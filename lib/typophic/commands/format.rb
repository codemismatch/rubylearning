# frozen_string_literal: true

require_relative "../tutorial_formatter"

module Typophic
  module Commands
    class Format
      def self.run(argv)
        new(argv).execute
      end

      def initialize(argv)
        @argv = argv
      end

      def execute
        root = Dir.pwd
        puts "Formatting tutorials in #{root}..."
        
        changed = Typophic::TutorialFormatter.format_all(root: root, backup: true)

        if changed.empty?
          puts "✅ No tutorial files required formatting."
        else
          changed.each { |path| puts "✏️  Formatted: #{path}" }
        end
      end
    end
  end
end
