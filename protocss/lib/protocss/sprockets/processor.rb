# frozen_string_literal: true

require 'sprockets'
require_relative '../plugins'

module Protocss
  module Sprockets
    # Sprockets processor for Protocss
    # Automatically processes CSS files through Tailwind, Autoprefixer, and Nested plugins
    class Processor
      class << self
        attr_accessor :config_path
      end

      def self.call(input)
        new(input).call
      end

      def initialize(input)
        @input = input
        @data = extract_data(input)
        @filename = extract_filename(input)
        @load_path = extract_load_path(input)
      end

      def call
        # Load Tailwind config
        config = load_tailwind_config

        # Create processor with plugins
        processor = create_processor(config)

        # Process CSS
        result = processor.process(@data, from: @filename)

        # Return in Sprockets-compatible format
        if @input.is_a?(Hash)
          {
            data: result.css,
            dependencies: dependencies
          }
        else
          # For Sprockets 4.x, return string directly
          result.css
        end
      end

      private

      def extract_data(input)
        input[:data] || (input.respond_to?(:data) ? input.data : input.to_s)
      end

      def extract_filename(input)
        input[:filename] || (input.respond_to?(:filename) ? input.filename : 'input.css')
      end

      def extract_load_path(input)
        if input.is_a?(Hash)
          input[:load_path] || Dir.pwd
        elsif input.respond_to?(:load_path)
          input.load_path
        else
          Dir.pwd
        end
      end

      def create_processor(config)
        plugins = []

        # Add nested support if CSS contains nested rules
        plugins << Plugins.nested if needs_nested?

        # Add Tailwind plugin
        plugins << Plugins.tailwind(config)

        # Add autoprefixer
        plugins << Plugins.autoprefixer

        Protocss.new(plugins)
      end

      def load_tailwind_config
        # Use custom config path if set
        if self.class.config_path && File.exist?(self.class.config_path)
          return Plugins::Tailwind::ConfigLoader.load(self.class.config_path)
        end

        # Try multiple locations
        config_paths = build_config_paths

        config_paths.each do |path|
          return Plugins::Tailwind::ConfigLoader.load(path) if File.exist?(path)
        end

        # Return default config
        {}
      end

      def build_config_paths
        paths = []

        # Check in load path
        %w[tailwind.config.rb tailwind.config.yml tailwind.config.yaml tailwind.config.json].each do |file|
          paths << File.join(@load_path, file)
        end

        # Check in current directory
        %w[tailwind.config.rb tailwind.config.yml tailwind.config.yaml tailwind.config.json].each do |file|
          paths << File.join(Dir.pwd, file)
        end

        # Check in Rails root if in Rails
        if defined?(Rails)
          %w[tailwind.config.rb tailwind.config.yml tailwind.config.yaml tailwind.config.json].each do |file|
            paths << Rails.root.join(file).to_s
            paths << Rails.root.join('config', file).to_s
          end
        end

        paths
      end

      def needs_nested?
        # Check if CSS contains nested rules (simple heuristic)
        @data.match?(/\{[^}]*\{/)
      end

      def dependencies
        deps = Set.new

        # Add config files as dependencies
        config_paths = build_config_paths

        config_paths.each do |path|
          full_path = File.expand_path(path)
          if File.exist?(full_path)
            deps << full_path
          end
        end

        deps
      end
    end
  end
end

# Register with Sprockets if available
if defined?(::Sprockets)
  # For Sprockets 4.x
  begin
    if ::Sprockets.respond_to?(:register_transformer)
      ::Sprockets.register_mime_type 'text/css', extensions: ['.css'] unless ::Sprockets.mime_types.key?('text/css')
      ::Sprockets.register_transformer 'text/css', 'text/css', Protocss::Sprockets::Processor
    end
  rescue StandardError => e
    # Sprockets may not be fully initialized yet
    # Registration will happen when processor is first used
  end
end
