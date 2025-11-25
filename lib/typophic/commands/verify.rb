# frozen_string_literal: true

require "open3"
require "json"

module Typophic
  module Commands
    class Verify
      def self.run(argv)
        new(argv).execute
      end

      def initialize(argv)
        @argv = argv
      end

      def execute
        project_root = Dir.pwd
        # Default to checking all tutorials if no specific files are passed
        files = if @argv.empty?
                  Dir.glob(File.join(project_root, "content", "pages", "tutorials", "*.md"))
                else
                  @argv.map { |f| File.expand_path(f, project_root) }
                end

        failures = []

        files.each do |path|
          rel_path = path.sub("#{project_root}/", "")
          begin
            content = File.read(path)
          rescue Errno::ENOENT => e
            failures << { chapter: rel_path, reason: "File not found: #{e.message}" }
            next
          end

          # Find all solution and test blocks (order matters)
          solution_blocks = content.scan(/```solution\n(.*?)\n```/m).map(&:first)
          test_blocks = content.scan(/```test\n(.*?)\n```/m).map(&:first)

          solution_blocks.each_with_index do |sol, idx|
            test = test_blocks[idx]
            next unless test

            # Execute solution code safely
            stdout, _stderr, _status = Open3.capture3("ruby", "-e", sol)
            output = stdout

            # Prepare test code: replace any legacy `output.string` usage with plain `output`
            cleaned_test = test.gsub(/output\.string/, "output")
            test_code = "output = #{output.dump}\n" + cleaned_test

            begin
              test_result = eval(test_code)
              unless test_result
                failures << { chapter: rel_path, index: idx + 1, reason: "Test returned false" }
              end
            rescue Exception => e
              failures << { chapter: rel_path, index: idx + 1, reason: e.message }
            end
          end
        end

        if failures.empty?
          puts "✅ All tests passed in #{files.size} file(s)."
        else
          puts "❌ Failures (#{failures.size}):"
          failures.each do |f|
            puts "- #{f[:chapter]}#{f[:index] ? " (block #{f[:index]})" : ''}: #{f[:reason]}"
          end
          exit 1
        end
      end
    end
  end
end
