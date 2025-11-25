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
        setup_file_system

        template = ::Liquid::Template.parse(template_body)
        
        payload = {
          "site" => @site,
          "page" => @page,
          "content" => @content
        }

        registers = {
          site: @site,
          page: @page,
          theme: @current_theme,
          site_includes_dir: @site_includes_dir,
          theme_includes_dir: @theme_includes_dir,
          builder: @builder
        }

        template.render(payload, registers: registers)
      end

      private

      def register_filters
        unless ::Liquid::Template.error_mode == :strict
          ::Liquid::Template.register_filter(Typophic::LiquidFilters)
        end
      end

      def setup_file_system
        roots = []
        roots << @site_includes_dir if Dir.exist?(@site_includes_dir)
        roots << @theme_includes_dir if @theme_includes_dir && Dir.exist?(@theme_includes_dir)
        
        # Use the most specific root (theme includes) if available, or site includes
        root = roots.find { |r| r && Dir.exist?(r) } || "."
        
        ::Liquid::Template.file_system = ::Liquid::LocalFileSystem.new(root, "%s.html")
      end
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

    def relative_url(input)
      site = @context.registers[:site]
      base_path = site["base_path"] || ""
      combine_with_base(input.to_s, base_path)
    end
    
    def url_for(input)
      relative_url(input)
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
