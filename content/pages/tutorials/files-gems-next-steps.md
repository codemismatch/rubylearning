---
layout: tutorial
title: Chapter 6 &ndash; Files, gems & next steps
permalink: /tutorials/files-gems-next-steps/
difficulty: advanced
summary: Read external data, interact with the filesystem, and script with gems to automate real tasks.
previous_tutorial:
  title: "Chapter 5: Modules & mixins"
  url: /tutorials/modules-and-mixins/
related_tutorials:
  - title: "Rails project setup"
    url: /tutorials/rails-project-setup/
  - title: "Ruby resources"
    url: /pages/resources/
---

> Revived from RubyLearning's tutorials by Satish Talim, with updates for modern Ruby development.

Real applications interact with files, the command line, and external libraries. This example reads data, transforms it, and prints a report.

### Read/Write Files {#file-io}

In a typical Ruby environment, you can read/write to files using methods like `File.open`, `File.read`, and `File.write`. Since we're using a browser-based Ruby environment, file operations may be limited to simulated examples:

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
# In a traditional Ruby environment, you would write:
# Writing to a file
# File.open(&quot;sample.txt&quot;, &quot;w&quot;) do |file|
#   file.puts &quot;This is the first line&quot;
#   file.puts &quot;This is the second line&quot;
#   file.puts &quot;Ruby file handling is easy!&quot;
# end

# Reading from a file
# File.open(&quot;sample.txt&quot;, &quot;r&quot;) do |file|
#   file.each_line do |line|
#     puts &quot;Read: #{line.chomp}&quot;
#   end
# end

# These examples demonstrate file operations conceptually
puts &quot;This is the first line&quot;
puts &quot;This is the second line&quot;
puts &quot;Ruby file handling is easy!&quot;

# Alternative ways to work with text data in our environment
content = &quot;Line 1\nLine 2\nLine 3&quot;
puts &quot;Sample content: #{content}&quot;  # Fixed interpolation
lines = content.split(&quot;\n&quot;)
puts &quot;Lines as array: #{lines.inspect}&quot;  # Fixed interpolation
</code></pre>

### CSV pipelines {#csv}

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
require &#39;csv&#39;

sample_scores = &lt;&lt;~CSV
  name,score
  Alice,95
  Bob,85
  Charlie,92
CSV

load_scores = -&gt;(csv_text) do
  CSV.parse(csv_text, headers: true).map do |row|
    { name: row[&#39;name&#39;], score: row[&#39;score&#39;].to_i }
  end
end

highlight_top_performers = -&gt;(records) do
  records.select { |record| record[:score] &gt;= 90 }
end

scores = load_scores.call(sample_scores)
highlight_top_performers.call(scores).each do |record|
  puts &quot;#{record[:name]} - #{record[:score]}&quot;  # Fixed interpolation
end
</code></pre>

### Ruby Exceptions {#exceptions}

An exception is a special kind of object, an instance of the class `Exception` or a descendant of that class that represents some kind of error:

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
divide_numbers = -&gt;(a, b) do
  begin
    result = a / b
    puts &quot;Result: #{result}&quot;  # Fixed interpolation
  rescue ZeroDivisionError
    puts &quot;Error: Cannot divide by zero!&quot;
  rescue StandardError =&gt; e
    puts &quot;An error occurred: #{e.message}&quot;  # Fixed interpolation
  ensure
    puts &quot;Division operation completed.&quot;  # This always runs
  end
end

divide_numbers.call(10, 2)   # Works fine
divide_numbers.call(10, 0)   # Triggers ZeroDivisionError

# Using raise to create custom exceptions
validate_age = -&gt;(age) do
  raise ArgumentError, &quot;Age must be positive&quot; if age &lt; 0
  puts &quot;Valid age: #{age}&quot;  # Fixed interpolation
rescue ArgumentError =&gt; e
  puts &quot;Validation error: #{e.message}&quot;  # Fixed interpolation
end

validate_age.call(25)   # Valid
validate_age.call(-5)   # Triggers ArgumentError
</code></pre>

### Ruby Logging {#logging}

The `Logger` class in the Ruby standard library helps write log messages to a file or stream. It supports time- or size-based rolling of log files:

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
require &#39;logger&#39;
require &#39;stringio&#39;

# Capture logs so the interactive runner can display them reliably
log_output = StringIO.new
logger = Logger.new(log_output)

# Format entries without timestamps for clarity in the lesson
logger.formatter = proc do |severity, _datetime, _progname, msg|
  &quot;#{severity}: #{msg}\n&quot;
end

logger.info(&quot;Application started&quot;)
logger.warn(&quot;This is a warning message&quot;)
logger.error(&quot;An error occurred&quot;)
logger.fatal(&quot;A fatal error occurred&quot;)

# Different log levels: debug &lt; info &lt; warn &lt; error &lt; fatal
logger.level = Logger::WARN  # Only show warnings and above

logger.debug(&quot;This won&#39;t be shown due to level setting&quot;)
logger.error(&quot;This error will be shown&quot;)

puts log_output.string
</code></pre>

### Ruby Time Class {#time}

The `Time` class in Ruby has a powerful formatting function which can help you represent the time in a variety of ways:

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
# Getting current time
now = Time.now
puts &quot;Current time: #{now}&quot;  # Fixed interpolation

# Formatting time
puts &quot;Formatted: #{now.strftime(&#39;%Y-%m-%d %H:%M:%S&#39;)}&quot;
puts &quot;Date only: #{now.strftime(&#39;%d/%m/%Y&#39;)}&quot;
puts &quot;Time only: #{now.strftime(&#39;%H:%M:%S&#39;)}&quot;

# Creating specific times
specific_time = Time.new(2025, 12, 25, 10, 30, 0)
puts &quot;Christmas 2025: #{specific_time}&quot;  # Fixed interpolation

# Time arithmetic
future = now + (60 * 60 * 24)  # Add one day (24 hours * 60 minutes * 60 seconds)
puts &quot;Tomorrow: #{future}&quot;

# Calculating time differences
duration = future - now
puts &quot;Time difference in seconds: #{duration}&quot;
puts &quot;Time difference in days: #{duration / (60 * 60 * 24)}&quot;

# Parsing time strings
parsed_time = Time.parse(&quot;2025-12-25 10:30:00&quot;)
puts &quot;Parsed time: #{parsed_time}&quot;
</code></pre>

### Object Serialization {#serialization}

Ruby comes with built-in object serialization capabilities similar to Java's serialization:

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
require &#39;json&#39;
require &#39;yaml&#39;

# Creating a sample object
person = {
name: &quot;Alice&quot;,
age: 30,
hobbies: [&quot;reading&quot;, &quot;swimming&quot;, &quot;coding&quot;],
active: true
}

# JSON serialization
json_string = JSON.generate(person)
puts &quot;JSON: #{json_string}&quot;  # Fixed interpolation

# JSON deserialization
parsed_json = JSON.parse(json_string)
puts &quot;Parsed from JSON: #{parsed_json}&quot;

# YAML serialization
yaml_string = person.to_yaml
puts &quot;YAML: #{yaml_string}&quot;

# YAML deserialization
parsed_yaml = YAML.safe_load(yaml_string)
puts &quot;Parsed from YAML: #{parsed_yaml}&quot;
</code></pre>

### Regular Expressions {#regex}

Regular expressions, though cryptic, is a powerful tool for working with text. Ruby has this feature built-in. It's used for pattern-matching:

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
# Basic pattern matching
text = &quot;Contact us at info@example.com or support@company.org&quot;
email_pattern = /\w+@\w+\.\w+/

# Match the pattern
if text.match?(email_pattern)
  puts &quot;Found an email pattern!&quot;
end

# Find first match
first_email = text[/.+@.+\...+/]
puts &quot;First email: #{first_email}&quot;

# Find all matches
all_emails = text.scan(/[\w.]+@[\w.]+\.\w+/)
puts &quot;All emails: #{all_emails.inspect}&quot;

# Replace text with regex
sentence = &quot;The cat in the hat sat on the mat&quot;
new_sentence = sentence.gsub(/at/, &quot;XX&quot;)
puts &quot;Modified: #{new_sentence}&quot;

# Using regex with capture groups
phone = &quot;Call me at (555) 123-4567&quot;
if match = phone.match(/\((\d{3})\) (\d{3})-(\d{4})/)
  area_code, exchange, number = match.captures
  puts &quot;Area code: #{area_code}, Exchange: #{exchange}, Number: #{number}&quot;
end
</code></pre>

### Including Other Files {#including-files}

Ruby provides several ways to include code from other files:

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
# require - includes a file once during execution
# require &#39;json&#39;  # Example: including a library

# require_relative - includes a file relative to current file
# require_relative &#39;./my_module&#39;

# load - includes a file every time it&#39;s called
# load &#39;./my_script.rb&#39;

# For this example, we&#39;ll demonstrate with a string that represents a module
# In practice, you would have separate files.
</code></pre>

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
- Move into the Rails sprint, starting with [Chapter R1: Project setup](/tutorials/rails-project-setup/).
- Keep useful references close by using the [resources page](/pages/resources/).
