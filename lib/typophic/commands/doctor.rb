# frozen_string_literal: true

require "yaml"

module Typophic
  module Commands
    module Doctor
      module_function

      def run(_argv)
        ok = true

        ok &= check_file("config.yml", required: true)
        ok &= check_dir("content", required: true)
        ok &= check_dir("themes", required: true)
        ok &= check_theme_config

        puts ok ? "All checks passed." : "Some checks failed. See messages above."
        exit(1) unless ok
      end

      def check_file(path, required: false)
        if File.file?(path)
          puts "✓ Found #{path}"
          true
        else
          warn(required ? "✗ Missing required file: #{path}" : "! Optional file not found: #{path}")
          !required
        end
      end

      def check_dir(path, required: false)
        if Dir.exist?(path)
          puts "✓ Found #{path}/"
          true
        else
          warn(required ? "✗ Missing required directory: #{path}/" : "! Optional directory not found: #{path}/")
          !required
        end
      end

      def check_theme_config
        cfg = YAML.load_file("config.yml") rescue {}
        theme = cfg["theme"]
        names = case theme
                when String then [theme]
                when Hash
                  arr = []
                  arr << theme["default"] if theme["default"]
                  (theme["sections"] || {}).each_value { |v| arr << v }
                  arr
                else []
                end

        return true if names.empty?

        missing = names.reject { |n| Dir.exist?(File.join("themes", n.to_s)) }
        if missing.empty?
          puts "✓ Theme(s) present: #{names.uniq.join(', ')}"
          true
        else
          warn "✗ Missing theme directories under themes/: #{missing.join(', ')}"
          false
        end
      end
    end
  end
end

