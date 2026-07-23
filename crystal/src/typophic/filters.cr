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

        # Fall back to the default theme when the requested theme doesn't
        # ship this asset (e.g. pylearning inherits rubylearning's JS).
        default_theme = FilterConfig.default_theme
        if !default_theme.empty? && theme_name != default_theme &&
           !File.exists?(File.join("themes", theme_name, asset)) &&
           File.exists?(File.join("themes", default_theme, asset))
          theme_name = default_theme
        end

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

module Typophic
  module Filters
    # Extended `date` filter: like Liquid's stock filter but also parses
    # string dates from frontmatter ("2025-10-30", "2025-10-30 00:00:00 UTC"),
    # not just Time values. Registered under the same name so it overrides
    # the stock implementation.
    class Date
      extend Liquid::Filters::Filter

      def self.filter(data : Liquid::Any, args : Array(Liquid::Any), options : Hash(String, Liquid::Any)) : Liquid::Any
        format = args.first?.try(&.as_s?)
        return data unless format

        if time = data.as_t?
          Liquid::Any.new time.to_s format
        elsif str = data.as_s?
          if str == "now" || str == "today"
            Liquid::Any.new Time.utc.to_s format
          elsif time = parse_time_string(str)
            Liquid::Any.new time.to_s format
          else
            data
          end
        else
          data
        end
      end

      private def self.parse_time_string(str : String) : Time?
        s = str.strip
        {"%Y-%m-%d %H:%M:%S %z", "%Y-%m-%d %H:%M:%S", "%Y-%m-%d", "%Y-%m-%dT%H:%M:%S"}.each do |fmt|
          begin
            return Time.parse(s, fmt, Time::Location::UTC)
          rescue Time::Format::Error
          end
        end

        # Tolerate a trailing UTC/GMT zone name
        stripped = s.sub(/\s+(UTC|GMT)\s*$/, "")
        {"%Y-%m-%d %H:%M:%S", "%Y-%m-%d"}.each do |fmt|
          begin
            return Time.parse(stripped, fmt, Time::Location::UTC)
          rescue Time::Format::Error
          end
        end
        nil
      end
    end
  end
end

Liquid::Filters::FilterRegister.register "date", Typophic::Filters::Date
