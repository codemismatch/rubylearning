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
        # Get or create shared environment with filters/tags registered
        env = get_or_create_environment
        
        template = if env
                     # Use Environment API (Liquid 5.x)
                     ::Liquid::Template.parse(template_body, environment: env)
                   else
                     # Fallback to old API
                     ::Liquid::Template.parse(template_body)
                   end
        
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

      class << self
        attr_accessor :environment_mutex, :shared_environment
      end
      
      self.environment_mutex = Mutex.new
      self.shared_environment = nil

      def get_or_create_environment
        return self.class.shared_environment if self.class.shared_environment
        
        self.class.environment_mutex.synchronize do
          return self.class.shared_environment if self.class.shared_environment
          
          # Create Environment instance and register filters/tags (Liquid 5.x API)
          if defined?(::Liquid::Environment)
            env = ::Liquid::Environment.new
            env.register_filter(Typophic::LiquidFilters)
            env.register_tag("include", Typophic::LiquidTags::Include)
            env.register_tag("include_cached", Typophic::LiquidTags::IncludeCached)
            self.class.shared_environment = env
          else
            # Fallback for older Liquid versions - use deprecated API
            old_verbose = $VERBOSE
            $VERBOSE = nil
            begin
              ::Liquid::Template.register_filter(Typophic::LiquidFilters)
              ::Liquid::Template.register_tag("include", Typophic::LiquidTags::Include)
              ::Liquid::Template.register_tag("include_cached", Typophic::LiquidTags::IncludeCached)
            ensure
              $VERBOSE = old_verbose
            end
            self.class.shared_environment = nil
          end
        end
        
        self.class.shared_environment
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
      input_str = input.to_s
      return input_str if input_str =~ %r{^https?://}

      theme = theme_name || @context.registers[:theme]
      site = @context.registers[:site]
      base_path = site["base_path"] || ""

      relative = input_str.sub(%r{^/}, "")

      # Fall back to the default theme when the requested theme doesn't
      # ship this asset (e.g. pylearning inherits rubylearning's JS).
      theme_cfg = site["theme"]
      default_theme = theme_cfg.is_a?(Hash) ? theme_cfg["default"].to_s : "rubylearning"
      default_theme = "rubylearning" if default_theme.empty?
      if theme.to_s != default_theme &&
         !File.exist?(File.join("themes", theme.to_s, relative)) &&
         File.exist?(File.join("themes", default_theme, relative))
        theme = default_theme
      end

      path = File.join("themes", theme.to_s, relative)
      combine_with_base(path, base_path)
    end

    def theme_path(input = "", theme_name = nil)
      name = theme_name || @context.registers[:theme]
      site = @context.registers[:site]
      base_path = site["base_path"] || ""

      relative = input.to_s.sub(%r{^/}, "")
      path = File.join("themes", name.to_s, relative)
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
