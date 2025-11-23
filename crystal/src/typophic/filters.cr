# frozen_string_literal: true

require "liquid"
require "uri"

module Typophic
  # Shared configuration for custom Liquid filters.
  module FilterConfig
    @@base_path = ""
    @@base_url = ""
    @@default_theme = ""

    def self.configure(base_path : String?, base_url : String?, default_theme : String?)
      @@base_path = base_path || ""
      @@base_url = base_url || ""
      @@default_theme = default_theme || ""
    end

    def self.base_path
      @@base_path
    end

    def self.base_url
      @@base_url
    end

    def self.default_theme
      @@default_theme
    end
  end

  module Filters
    # Build a URL by combining a base path with a relative path.
    def self.build_relative(path : String, base_path : String) : String
      clean_relative = path.sub(/\A\//, "")
      return base_path.empty? ? "/" : "#{base_path}/" if clean_relative.empty?

      base = base_path.sub(/\/\z/, "")
      joined = "#{base}/#{clean_relative}"
      joined.gsub(/\/+/, "/")
    end

    # relative_url: prefixes the given path with the configured base_path or an optional override.
    class RelativeUrl
      extend Liquid::Filters::Filter

      def self.filter(data : Liquid::Any, args : Array(Liquid::Any), options : Hash(String, Liquid::Any)) : Liquid::Any
        path = data.to_s
        base_override = args.first?.try(&.to_s) || FilterConfig.base_path
        Liquid::Any.new(Typophic::Filters.build_relative(path, base_override))
      end
    end

    # theme_asset: build a theme-scoped asset path.
    # Usage: {{ "css/style.css" | theme_asset: page.theme }}
    class ThemeAsset
      extend Liquid::Filters::Filter

      def self.filter(data : Liquid::Any, args : Array(Liquid::Any), options : Hash(String, Liquid::Any)) : Liquid::Any
        asset = data.to_s.sub(/\A\//, "")
        theme_name = args.first?.try(&.to_s) || FilterConfig.default_theme
        base_override = args.size >= 2 ? args[1].to_s : FilterConfig.base_path
        path = "themes/#{theme_name}/#{asset}"
        Liquid::Any.new(Typophic::Filters.build_relative(path, base_override))
      end
    end

    # url_for: general URL helper (relative to base_path).
    class UrlFor
      extend Liquid::Filters::Filter

      def self.filter(data : Liquid::Any, args : Array(Liquid::Any), options : Hash(String, Liquid::Any)) : Liquid::Any
        relative = data.to_s
        base_override = args.first?.try(&.to_s) || FilterConfig.base_path
        Liquid::Any.new(Typophic::Filters.build_relative(relative, base_override))
      end
    end

    # absolute_url: combines base_url and a relative path.
    class AbsoluteUrl
      extend Liquid::Filters::Filter

      def self.filter(data : Liquid::Any, args : Array(Liquid::Any), options : Hash(String, Liquid::Any)) : Liquid::Any
        path = data.to_s
        base_url = args.first?.try(&.to_s) || FilterConfig.base_url
        if base_url.empty?
          return Liquid::Any.new(Typophic::Filters.build_relative(path, FilterConfig.base_path))
        end

        # Ensure single slash join
        clean_path = path.starts_with?("/") ? path : "/#{path}"
        joined = "#{base_url.sub(%r{/$}, "")}#{clean_path}"
        Liquid::Any.new(joined)
      end
    end
  end
end

# Register custom filters with Liquid
Liquid::Filters::FilterRegister.register "relative_url", Typophic::Filters::RelativeUrl
Liquid::Filters::FilterRegister.register "theme_asset", Typophic::Filters::ThemeAsset
Liquid::Filters::FilterRegister.register "url_for", Typophic::Filters::UrlFor
Liquid::Filters::FilterRegister.register "absolute_url", Typophic::Filters::AbsoluteUrl
