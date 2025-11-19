# frozen_string_literal: true

require "rubocop"

module Typophic
  class InlineRuboCop
    class << self
      def instance
        @instance ||= new
      end
    end

    def initialize(config_path: ".rubocop.yml")
      @config_store = RuboCop::ConfigStore.new
      if config_path && File.exist?(config_path)
        @config_store.options_config = config_path
      end
    end

    def format(source_code, file: "(string)")
      require 'tempfile'
      
      # Write source to a temporary file for RuboCop to process
      Tempfile.create(['rubocop', '.rb']) do |temp_file|
        temp_file.write(source_code)
        temp_file.close
        
        # Run RuboCop autocorrect on the file
        options = {
          autocorrect: true,
          safe_autocorrect: false, # Allow unsafe corrections too
          formatters: [] # No output
        }
        
        runner = RuboCop::Runner.new(options, @config_store)
        runner.run([temp_file.path])
        
        # Read the corrected content
        corrected = File.read(temp_file.path)
        
        # Return corrected code or original if nothing changed
        corrected.empty? ? source_code : corrected
      end
    rescue StandardError => e
      # Silently return original code on any error
      source_code
    end
  end
end
