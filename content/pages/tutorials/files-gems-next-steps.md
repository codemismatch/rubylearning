---
layout: tutorial
title: Chapter 6 &ndash; Files, gems & next steps
permalink: /courses/ruby-basics/files-gems-next-steps/
difficulty: advanced
summary: Read external data, interact with the filesystem, and script with gems to automate real tasks.
previous_tutorial:
  title: "Chapter 5: Modules & mixins"
  url: /courses/ruby-basics/modules-and-mixins/
related_tutorials:
  - title: "Rails project setup"
    url: /courses/ruby-basics/rails-project-setup/
  - title: "Ruby resources"
    url: /pages/resources/
date: 2025-10-31
---

> Revived from RubyLearning's tutorials by Satish Talim, with updates for modern Ruby development.

Real applications interact with files, the command line, and external libraries. This example reads data, transforms it, and prints a report.

### Read/Write Files {#file-io}

In a typical Ruby environment, you can read/write to files using methods like `File.open`, `File.read`, and `File.write`. Since we're using a browser-based Ruby environment, file operations may be limited to simulated examples:

```ruby-exec
# In a traditional Ruby environment, you would write:
# Writing to a file
# File.open("sample.txt", "w") do |file|
#   file.puts "This is the first line"
#   file.puts "This is the second line"
#   file.puts "Ruby file handling is easy!"
# end

# Reading from a file
# File.open("sample.txt", "r") do |file|
#   file.each_line do |line|
#     puts "Read: #{line.chomp}"
#   end
# end

# These examples demonstrate file operations conceptually
puts "This is the first line"
puts "This is the second line"
puts "Ruby file handling is easy!"

# Alternative ways to work with text data in our environment
content = "Line 1\nLine 2\nLine 3"
puts "Sample content: #{content}"  # Fixed interpolation
lines = content.split("\n")
puts "Lines as array: #{lines.inspect}"  # Fixed interpolation
```

### CSV pipelines {#csv}

```ruby-exec
require 'csv'

sample_scores = <<~CSV
  name,score
  Alice,95
  Bob,85
  Charlie,92
CSV

load_scores = ->(csv_text) do
  CSV.parse(csv_text, headers: true).map do |row|
    { name: row['name'], score: row['score'].to_i }
  end
end

highlight_top_performers = ->(records) do
  records.select { |record| record[:score] >= 90 }
end

scores = load_scores.call(sample_scores)
highlight_top_performers.call(scores).each do |record|
  puts "#{record[:name]} - #{record[:score]}"  # Fixed interpolation
end
```

### Ruby Exceptions {#exceptions}

An exception is a special kind of object, an instance of the class `Exception` or a descendant of that class that represents some kind of error:

```ruby-exec
divide_numbers = ->(a, b) do
  begin
    result = a / b
    puts "Result: #{result}"  # Fixed interpolation
  rescue ZeroDivisionError
    puts "Error: Cannot divide by zero!"
  rescue StandardError => e
    puts "An error occurred: #{e.message}"  # Fixed interpolation
  ensure
    puts "Division operation completed."  # This always runs
  end
end

divide_numbers.call(10, 2)   # Works fine
divide_numbers.call(10, 0)   # Triggers ZeroDivisionError

# Using raise to create custom exceptions
validate_age = ->(age) do
  raise ArgumentError, "Age must be positive" if age < 0
  puts "Valid age: #{age}"  # Fixed interpolation
rescue ArgumentError => e
  puts "Validation error: #{e.message}"  # Fixed interpolation
end

validate_age.call(25)   # Valid
validate_age.call(-5)   # Triggers ArgumentError
```

### Ruby Logging {#logging}

The `Logger` class in the Ruby standard library helps write log messages to a file or stream. It supports time- or size-based rolling of log files:

```ruby-exec
require 'logger'
require 'stringio'

# Capture logs so the interactive runner can display them reliably
log_output = StringIO.new
logger = Logger.new(log_output)

# Format entries without timestamps for clarity in the lesson
logger.formatter = proc do |severity, _datetime, _progname, msg|
  "#{severity}: #{msg}\n"
end

logger.info("Application started")
logger.warn("This is a warning message")
logger.error("An error occurred")
logger.fatal("A fatal error occurred")

# Different log levels: debug < info < warn < error < fatal
logger.level = Logger::WARN  # Only show warnings and above

logger.debug("This won't be shown due to level setting")
logger.error("This error will be shown")

puts log_output.string
```

### Ruby Time Class {#time}

The `Time` class in Ruby has a powerful formatting function which can help you represent the time in a variety of ways:

```ruby-exec
# Getting current time
now = Time.now
puts "Current time: #{now}"  # Fixed interpolation

# Formatting time
puts "Formatted: #{now.strftime('%Y-%m-%d %H:%M:%S')}"
puts "Date only: #{now.strftime('%d/%m/%Y')}"
puts "Time only: #{now.strftime('%H:%M:%S')}"

# Creating specific times
specific_time = Time.new(2025, 12, 25, 10, 30, 0)
puts "Christmas 2025: #{specific_time}"  # Fixed interpolation

# Time arithmetic
future = now + (60 * 60 * 24)  # Add one day (24 hours * 60 minutes * 60 seconds)
puts "Tomorrow: #{future}"

# Calculating time differences
duration = future - now
puts "Time difference in seconds: #{duration}"
puts "Time difference in days: #{duration / (60 * 60 * 24)}"

# Parsing time strings
parsed_time = Time.parse("2025-12-25 10:30:00")
puts "Parsed time: #{parsed_time}"
```

### Object Serialization {#serialization}

Ruby comes with built-in object serialization capabilities similar to Java's serialization:

```ruby-exec
require 'json'
require 'yaml'

# Creating a sample object
person = {
name: "Alice",
age: 30,
hobbies: ["reading", "swimming", "coding"],
active: true
}

# JSON serialization
json_string = JSON.generate(person)
puts "JSON: #{json_string}"  # Fixed interpolation

# JSON deserialization
parsed_json = JSON.parse(json_string)
puts "Parsed from JSON: #{parsed_json}"

# YAML serialization
yaml_string = person.to_yaml
puts "YAML: #{yaml_string}"

# YAML deserialization
parsed_yaml = YAML.safe_load(yaml_string)
puts "Parsed from YAML: #{parsed_yaml}"
```

### Regular Expressions {#regex}

Regular expressions, though cryptic, is a powerful tool for working with text. Ruby has this feature built-in. It's used for pattern-matching:

```ruby-exec
# Basic pattern matching
text = "Contact us at info@example.com or support@company.org"
email_pattern = /\w+@\w+\.\w+/

# Match the pattern
if text.match?(email_pattern)
  puts "Found an email pattern!"
end

# Find first match
first_email = text[/.+@.+\...+/]
puts "First email: #{first_email}"

# Find all matches
all_emails = text.scan(/[\w.]+@[\w.]+\.\w+/)
puts "All emails: #{all_emails.inspect}"

# Replace text with regex
sentence = "The cat in the hat sat on the mat"
new_sentence = sentence.gsub(/at/, "XX")
puts "Modified: #{new_sentence}"

# Using regex with capture groups
phone = "Call me at (555) 123-4567"
if match = phone.match(/\((\d{3})\) (\d{3})-(\d{4})/)
  area_code, exchange, number = match.captures
  puts "Area code: #{area_code}, Exchange: #{exchange}, Number: #{number}"
end
```

### Including Other Files {#including-files}

Ruby provides several ways to include code from other files:

```ruby-exec
# require - includes a file once during execution
# require 'json'  # Example: including a library

# require_relative - includes a file relative to current file
# require_relative './my_module'

# load - includes a file every time it's called
# load './my_script.rb'

# For this example, we'll demonstrate with a string that represents a module
# In practice, you would have separate files.
```

### Practice checklist

- Read and write files using different methods (File.open, File.read, File.write)
- Handle exceptions in your code with begin/rescue/ensure blocks
- Use the Logger class for proper logging in applications
- Work with Time objects to handle dates and times
- Practice object serialization with JSON and YAML
- Experiment with regular expressions for text processing
- Include code from other files using require/require_relative

Next steps:

- Revisit earlier chapters and replace hard-coded data with user input.
- Practice building real-world applications that combine all these concepts.
- Move into the Rails sprint, starting with [Chapter R1: Project setup](/courses/ruby-basics/rails-project-setup/).
- Keep useful references close by using the [resources page](/pages/resources/).

#### Practice 1 - Sketching a file IO script

**Goal:** Outline a small script that uses `File.open`, `File.read`, and `File.write`.

#> ruby :practice

# TODO: Print a short outline of a script that would read from one
# file and write to another using File.open/File.read/File.write.
# This environment doesn't touch your real filesystem, so focus on
# the code you would write, not actually running it.

```solution
puts 'data = File.read("input.txt")'
puts 'File.write("output.txt", data)'
```

```test
out = output.string; lines = out.lines.map(&:strip); %w[File.read File.write].all? { |tok| lines.any? { |l| l.include?(tok) } }
```

#!


#### Practice 2 - Thinking through exception handling

**Goal:** Show how you would use `begin`/`rescue`/`ensure` around IO.

#> ruby :practice

# TODO: Print a minimal begin/rescue/ensure snippet that would wrap a
# file operation and handle errors gracefully.

```solution
puts "begin"
puts "  File.read('config.yml')"
puts "rescue Errno::ENOENT"
puts "  puts 'Missing config file'"
puts "ensure"
puts "  puts 'cleanup if needed'"
```

```test
out = output.string; lines = out.lines.map(&:strip); %w[begin rescue ensure].all? { |kw| lines.any? { |l| l.include?(kw) } }
```

#!


#### Practice 3 - Logging and time usage

**Goal:** Describe how you would use `Logger` and `Time` in a small script.

#> ruby :practice

# TODO: Print one or two lines that show how you might construct a
# Logger and log a message with the current time.

```solution
puts "logger = Logger.new('log/app.log')"
puts "logger.info(\"Started at \#{Time.now}\")"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('Logger.new') } && lines.any? { |l| l.include?('Time.now') }
```

#!


#### Practice 4 - JSON/YAML and regex sketch

**Goal:** Sketch how you would serialize data to JSON/YAML and use a regexp to filter text.

#> ruby :practice

# TODO: Print a small snippet (as plain text) that mentions using
# JSON/YAML for serialization and a regular expression for filtering.

```solution
puts 'data = { name: "Rubyist" }'
puts 'json = JSON.dump(data)'
puts 'yaml = YAML.dump(data)'
puts 'matches = "Ruby 3.3.0".scan(/\d+\.\d+\.\d+/)'
```

```test
out = output.string; lines = out.lines.map(&:strip); %w[JSON YAML /\\w+/].any? { |tok| lines.any? { |l| l.include?(tok) } }
```

#!

