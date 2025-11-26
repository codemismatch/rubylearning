# frozen_string_literal: true

require 'yaml'
require 'json'

module Protocss
  module Plugins
    module Tailwind
      class ConfigLoader
        DEFAULT_PATHS = [
          'tailwind.config.rb',
          'tailwind.config.yml',
          'tailwind.config.yaml',
          'tailwind.config.json'
        ].freeze

        def self.load(path)
          new.load(path)
        end

        def self.load_default
          new.load_default
        end

        def load(path)
          return {} unless File.exist?(path)

          case File.extname(path)
          when '.rb'
            load_ruby_config(path)
          when '.yml', '.yaml'
            load_yaml_config(path)
          when '.json'
            load_json_config(path)
          else
            {}
          end
        end

        def load_default
          DEFAULT_PATHS.each do |path|
            return load(path) if File.exist?(path)
          end
          default_config
        end

        private

        def load_ruby_config(path)
          # Load Ruby file and evaluate
          # In production, use a safer method like Kernel.load with binding
          config_content = File.read(path)
          # Remove 'module.exports =' or similar if present
          config_content = config_content.gsub(/^\s*module\.exports\s*=\s*/, '')
          eval(config_content)
        rescue StandardError => e
          warn "Error loading Ruby config: #{e.message}"
          {}
        end

        def load_yaml_config(path)
          YAML.safe_load(File.read(path), permitted_classes: [Symbol]) || {}
        rescue StandardError => e
          warn "Error loading YAML config: #{e.message}"
          {}
        end

        def load_json_config(path)
          JSON.parse(File.read(path)) || {}
        rescue StandardError => e
          warn "Error loading JSON config: #{e.message}"
          {}
        end

        def default_config
          {
            content: [],
            theme: {
              extend: {}
            },
            plugins: []
          }
        end
      end
    end
  end
end
