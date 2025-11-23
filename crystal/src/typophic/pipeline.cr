# frozen_string_literal: true

require "yaml"

module Typophic
  module Pipeline
    @@content_steps : Array(String)? = nil

    def self.content_steps : Array(String)
      @@content_steps ||= load_content_steps
    end

    private def self.load_content_steps : Array(String)
      # Prefer config.yml, mirroring the Ruby implementation.
      begin
        config_path = File.join(Dir.current, "config.yml")
        if File.exists?(config_path)
          raw = File.read(config_path)
          yaml = YAML.parse(raw)

          if root = yaml.as_h?
            if pipeline_any = root["pipeline"]?
              if pipeline_hash = pipeline_any.as_h?
                if steps_any = pipeline_hash["steps"]?
                  if steps_array = steps_any.as_a?
                    steps = steps_array.map(&.to_s).select { |s| !s.empty? }
                    return steps unless steps.empty?
                  end
                end
              end
            end
          end
        end
      rescue
        # Fall through to defaults on any error; Crystal binary should remain usable
      end

      default_steps
    end

    private def self.default_steps : Array(String)
      %w[rubocop_ruby_blocks hash_blocks ruby_exec practice_blocks ruby_pre_blocks markdown]
    end
  end
end
