#!/usr/bin/env ruby
# frozen_string_literal: true

# Script to convert tutorial markdown files to the new human-readable format:
# 1. Convert HTML entities (&lt;, &quot;, &gt;) to normal characters
# 2. Convert HTML <pre><code> blocks to ```ruby-exec blocks
# 3. Convert HTML practice blocks to new #> ruby :practice syntax
# 4. Convert HTML Goal lines to markdown **Goal:** format

require 'fileutils'

def convert_file(file_path)
  content = File.read(file_path)
  original = content.dup
  
  # 1. Convert HTML entities in code blocks (but not in attributes yet)
  # This is tricky - we need to be careful not to break HTML attributes
  
  # 2. Convert HTML <pre><code> blocks with data-executable to ```ruby-exec
  # Handle both single-line and multi-line attributes
  content.gsub!(%r{<pre class="language-ruby"[\s\S]*?data-executable="true"[\s\S]*?><code class="[^"]*">\s*\n(.*?)\n</code></pre>}m) do |match|
    code = $1
    # Unescape HTML entities in code
    code = code.gsub('&lt;', '<').gsub('&gt;', '>').gsub('&quot;', '"').gsub('&amp;', '&').gsub('&#39;', "'")
    "```ruby-exec\n#{code}\n```"
  end
  
  # 3. Convert practice blocks - handle multi-line HTML attributes
  # First, try with Goal line before practice block
  content.gsub!(%r{(<p><strong>Goal:</strong>\s*(.*?)</p>\s*)?<pre class="language-ruby"[\s\S]*?data-executable="true"[\s\S]*?data-practice-chapter="([^"]+)"[\s\S]*?data-practice-index="(\d+)"[\s\S]*?data-test="([^"]+)"[^>]*><code class="language-ruby">\s*\n(.*?)\n</code></pre>\s*<div class="practice-feedback"[^>]*></div>\s*<script type="text/plain"[^>]*data-practice-solution="[^"]+">\s*\n(.*?)\n</script>}m) do
    goal_line = $1
    goal = $2 ? $2.strip : nil
    practice_chapter = $3
    practice_index = $4
    test_code = $5
    todo_code = $6
    solution_code = $7
    
    # Unescape HTML entities
    if goal
      goal = goal.gsub('&lt;', '<').gsub('&gt;', '>').gsub('&quot;', '"').gsub('&amp;', '&')
    end
    todo_code = todo_code.gsub('&lt;', '<').gsub('&gt;', '>').gsub('&quot;', '"').gsub('&amp;', '&')
    solution_code = solution_code.gsub('&lt;', '<').gsub('&gt;', '>').gsub('&quot;', '"').gsub('&amp;', '&')
    
    result = ""
    result += "**Goal:** #{goal}\n\n" if goal
    result += <<~MARKDOWN
      #> ruby :practice

      #{todo_code.strip}

      ```solution
      #{solution_code.strip}
      ```

      ```test
      #{test_code}
      ```

      #!
    MARKDOWN
    result
  end
  
  # 4. Convert standalone HTML Goal lines (for cases where practice block conversion didn't catch them)
  content.gsub!(%r{<p><strong>Goal:</strong>\s*(.*?)</p>}) do
    goal = $1.strip
    goal = goal.gsub('&lt;', '<').gsub('&gt;', '>').gsub('&quot;', '"').gsub('&amp;', '&')
    "**Goal:** #{goal}"
  end
  
  # 5. Convert remaining HTML entities in regular text (be careful not to break code blocks)
  # Only convert entities that are clearly in text, not in code blocks
  # This is a conservative approach - we'll handle code blocks separately
  
  if content != original
    File.write(file_path, content)
    puts "Converted: #{file_path}"
    true
  else
    false
  end
end

# Find all tutorial files
tutorial_dir = File.join(__dir__, '..', 'content', 'pages', 'tutorials')
files = Dir.glob(File.join(tutorial_dir, '*.md'))

puts "Found #{files.length} tutorial files"
converted = 0

files.each do |file|
  if convert_file(file)
    converted += 1
  end
end

puts "\nConverted #{converted} files"
