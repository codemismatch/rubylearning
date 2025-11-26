# frozen_string_literal: true

require "liquid"

module Typophic
  module Renderer
    class Liquid
      def initialize(site:, page:, content:, site_includes_dir:, theme_includes_dir:, helpers: [], current_theme: nil, builder: nil)
        @site = site
        @page = page
        @content = content
        @site_includes_dir = site_includes_dir
        @theme_includes_dir = theme_includes_dir
        @helper_modules = helpers
        @current_theme = current_theme
        @builder = builder
      end

      def render(template_body)
        register_filters
        register_tags
        template = ::Liquid::Template.parse(template_body)
        
        payload = {
          "site" => @site,
          "page" => @page,
          "content" => @content,
          "jekyll" => { "environment" => ENV["JEKYLL_ENV"] || "development" }
        }

        registers = {
          site: @site,
          page: @page,
          theme: @current_theme,
          site_includes_dir: @site_includes_dir,
          theme_includes_dir: @theme_includes_dir,
          builder: @builder
        }

        file_system = create_file_system(registers)
        registers[:file_system] = file_system
        
        template.render(payload, registers: registers)
      end

      private

      @filter_mutex = Mutex.new

      def self.register_filters
        # Suppress deprecation warnings for Liquid 5.x compatibility
        old_verbose = $VERBOSE
        $VERBOSE = nil
        return if @filters_registered
        @filter_mutex.synchronize do
          return if @filters_registered
          # Suppress deprecation warning for Liquid 5.x compatibility

          old_verbose, $VERBOSE = $VERBOSE, nil

          ::Liquid::Template.register_filter(Typophic::LiquidFilters)

          $VERBOSE = old_verbose
          @filters_registered = true
        $VERBOSE = old_verbose
        end
      end

      def register_filters
        self.class.register_filters
      end

      def register_tags
        return if defined?(@tags_registered) && @tags_registered
        # Suppress deprecation warnings for Liquid 5.x compatibility
        old_verbose, $VERBOSE = $VERBOSE, nil
        ::Liquid::Template.register_tag("include", Typophic::LiquidTags::Include)
        ::Liquid::Template.register_tag("include_cached", Typophic::LiquidTags::IncludeCached)

        $VERBOSE = old_verbose
        @tags_registered = true
      end

      def create_file_system(registers)
        roots = []

        theme_includes = registers[:theme_includes_dir]
        if theme_includes.nil? && registers[:theme]
          theme_includes = File.join(Dir.pwd, "themes", registers[:theme], "includes")
        end
        roots << File.expand_path(theme_includes) if theme_includes && Dir.exist?(theme_includes)

        site_includes = registers[:site_includes_dir] || File.join(Dir.pwd, "includes")
        roots << File.expand_path(site_includes) if Dir.exist?(site_includes)

        roots << File.join(Dir.pwd, "includes") if roots.empty?

        Typophic::FileSystem.new(roots)
      end
    end
  end

  class FileSystem < ::Liquid::LocalFileSystem
    def initialize(roots)
      @roots = Array(roots)
    end

    def read_template_file(template_path)
      full_path = full_path(template_path)
      unless full_path
        warn "Liquid include missing: '#{template_path}' (roots: #{@roots.join(', ')})"
        raise Liquid::FileSystemError, "No such template '#{template_path}'"
      end
      File.read(full_path)
    end

    def full_path(template_path)
      # Strip leading slash to prevent absolute path resolution
      template_path = template_path.sub(/^\//, "")
      
      # Allow hyphens in template names
      unless valid_filename?(template_path)
        warn "Liquid include rejected template name: '#{template_path}'"
        raise Liquid::FileSystemError, "Illegal template name '#{template_path}'"
      end

      @roots.each do |root|
        path = File.join(root, "#{template_path}.html")
        return path if File.exist?(path)
        
        # Also try without .html extension if it was already stripped or not present
        path_no_ext = File.join(root, template_path)
        return path_no_ext if File.exist?(path_no_ext)
      end
      
      nil
    end
    
    def valid_filename?(path)
      return false if path.include?("..")
      # Allow alphanumeric, underscores, hyphens, slashes, and dots
      path.match?(/^[^.\/][a-zA-Z0-9_\-\/\.]+$/)
    end
  end

  module LiquidFilters
    def theme_asset(input, theme_name = nil)
      context = @context.registers[:builder]
      theme = theme_name || @context.registers[:theme]
      
      relative = input.to_s.sub(%r{^/}, "")
      site = @context.registers[:site]
      base_path = site["base_path"] || ""
      
      path = File.join("themes", theme.to_s, relative)
      combine_with_base(path, base_path)
    end

    def scssify(input)
      builder = @context.registers[:builder]
      return input unless builder && builder.sass_renderer

      source = @context.registers[:page] && @context.registers[:page]["path"]
      builder.sass_renderer.compile(input.to_s, filename: source)
    end

    def relative_url(input)
      return input if input.to_s =~ %r{^https?://}
      site = @context.registers[:site]
      base_path = site["base_path"] || ""
      combine_with_base(input.to_s, base_path)
    end
    
    def url_for(input)
      relative_url(input)
    end

    def absolute_url(input)
      return input if input.to_s =~ %r{^https?://}
      site = @context.registers[:site]
      url = site["url"] || ""
      base_path = site["base_path"] || ""
      path = combine_with_base(input.to_s, base_path)
      "#{url}#{path}"
    end

    def date_to_xmlschema(input)
      return "" if input.nil?
      time = input.is_a?(String) ? Time.parse(input) : input
      time.respond_to?(:xmlschema) ? time.xmlschema : input.to_s
    end
    
    def default(input, default_value)
      (input.nil? || input.to_s.empty?) ? default_value : input
    end

    private

    def combine_with_base(relative, base_path)
      clean_relative = relative.to_s
      return base_path.empty? ? "/" : "#{base_path}/" if clean_relative.empty? || clean_relative == "/"

      clean_relative = clean_relative.sub(%r{^/}, "")
      path = base_path.empty? ? "/#{clean_relative}" : "#{base_path}/#{clean_relative}"
      path.gsub(%r{//+}, "/")
    end
  end
end

module Typophic
  module LiquidTags
    # Include tag that accepts unquoted filenames (Jekyll-style) and supports cached include alias.
    class Include < ::Liquid::Include
      def initialize(tag_name, markup, tokens)
        if markup =~ /^\s*([^'"\s]+)(\s+|$)/
          first_token = Regexp.last_match(1)
          if first_token.include?(".") || first_token.include?("/")
            markup = markup.sub(first_token, "\"#{first_token}\"")
          end
        end
        super(tag_name, markup, tokens)
      end
    end

    # Minimal include_cached support: behaves like Liquid's include.
    class IncludeCached < ::Liquid::Include
    end
  end
end
