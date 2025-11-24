#!/usr/bin/env ruby
# verify_chapters.rb
# This script scans tutorial markdown files for solution and test code blocks,
# executes the solution, captures its stdout, then evaluates the test block.
# It reports any failures.

require 'open3'
require 'json'

# Determine project root (one level up from this script's directory)
PROJECT_ROOT = File.expand_path('..', __dir__)

CHAPTER_FILES = [
  'content/pages/tutorials/ruby-arrays.md',
  'content/pages/tutorials/ruby-ranges.md',
  'content/pages/tutorials/ruby-symbols.md',
  'content/pages/tutorials/ruby-hashes.md',
  'content/pages/tutorials/ruby-random-numbers.md',
  'content/pages/tutorials/read-write-files.md',
  'content/pages/tutorials/ruby-regular-expressions.md'
]

failures = []

CHAPTER_FILES.each do |rel_path|
  path = File.expand_path(rel_path, PROJECT_ROOT)
  begin
    content = File.read(path)
  rescue Errno::ENOENT => e
    failures << {chapter: rel_path, reason: "File not found: #{e.message}"}
    next
  end
  # Find all solution and test blocks (order matters)
  solution_blocks = content.scan(/```solution\n(.*?)\n```/m).map(&:first)
  test_blocks = content.scan(/```test\n(.*?)\n```/m).map(&:first)
  solution_blocks.each_with_index do |sol, idx|
    test = test_blocks[idx]
    next unless test
    # Execute solution code safely
    stdout, stderr, status = Open3.capture3('ruby', '-e', sol)
    output = stdout
    # Prepare test code: replace any legacy `output.string` usage with plain `output`
    cleaned_test = test.gsub(/output\.string/, 'output')
    test_code = "output = #{output.dump}\n" + cleaned_test
    begin
      test_result = eval(test_code)
      unless test_result
        failures << {chapter: rel_path, index: idx + 1, reason: 'Test returned false'}
      end
    rescue Exception => e
      failures << {chapter: rel_path, index: idx + 1, reason: e.message}
    end
  end
end

if failures.empty?
  puts 'All tests passed.'
else
  puts "Failures (#{failures.size}):"
  failures.each do |f|
    puts "- #{f[:chapter]}#{f[:index] ? " (block #{f[:index]})" : ''}: #{f[:reason]}"
  end
  exit 1
end
