# frozen_string_literal: true

module Typophic
  module Pipeline
    class << self
      def content_steps
        @content_steps ||= load_content_steps
      end

      private

      def load_content_steps
        # First try config.yml
        config_path = File.join(Dir.pwd, "config.yml")
        if File.exist?(config_path)
          require 'yaml'
          config = YAML.load_file(config_path)
          if config && config['pipeline'] && config['pipeline']['steps']
            steps = Array(config['pipeline']['steps']).map(&:to_s)
            return steps if steps.any?
          end
        end
        
        # Fall back to Pipelinefile (for backwards compatibility)
        pipeline_path = File.join(Dir.pwd, "Pipelinefile")
        if File.exist?(pipeline_path)
          dsl = DSL.new
          dsl.instance_eval(File.read(pipeline_path), pipeline_path)
          return dsl.steps if dsl.steps.any?
        end
        
        # Use defaults if nothing else works
        default_steps
      rescue StandardError
        default_steps
      end

      def default_steps
        %w[rubocop_ruby_blocks hash_blocks ruby_exec markdown]
      end
    end

    class DSL
      attr_reader :steps

      def initialize
        @steps = []
      end

      def content(step_names)
        @steps = Array(step_names).map(&:to_s)
      end
    end
  end
end
