---
layout: tutorial
title: "Chapter 33 &ndash; Ruby Exceptions"
permalink: /tutorials/ruby-exceptions/
difficulty: beginner
summary: Handle errors with `begin`/`rescue`, ensure cleanup, and raise your own exceptions when something goes wrong.
previous_tutorial:
  title: "Chapter 32: Ruby Access Control"
  url: /tutorials/ruby-access-control/
next_tutorial:
  title: "Chapter 34: Ruby Logging"
  url: /tutorials/ruby-logging/
related_tutorials:
  - title: "Read/Write Text Files"
    url: /tutorials/read-write-files/
  - title: "Ruby Procs & Lambdas"
    url: /tutorials/ruby-procs/
---

> Adapted from Satish Talim's "Ruby Exceptions" lesson.

Ruby uses exceptions to report runtime problems. Use `begin`/`rescue` blocks to catch them, `ensure` to run cleanup, and `raise` to signal your own errors.

### Basic pattern

<pre class="language-ruby"><code class="language-ruby">
begin
  risky_operation
rescue ZeroDivisionError => e
  puts "Oops: #{e.message}"
rescue StandardError => e
  puts "Generic error: #{e.class}"
else
  puts "No errors!"
ensure
  puts "Always runs"
end
</code></pre>

- `rescue SpecificError => e` lets you branch per exception type.
- `else` executes only when no exception was raised.
- `ensure` runs regardless of success or failure--perfect for closing files or releasing resources.

### Raising exceptions

`raise` (alias `fail`) triggers an exception:

<pre class="language-ruby"><code class="language-ruby">
raise &quot;Something went wrong&quot;
raise ArgumentError, &quot;Bad argument&quot;
raise ArgumentError.new(&quot;Bad argument&quot;)
</code></pre>

Calling `raise` with no arguments inside `rescue` re-raises the current exception.

### Legacy example

<pre class="language-ruby"><code class="language-ruby">
def divide(x, y)
  raise ArgumentError, "y must not be zero" if y.zero?
  x / y
end

begin
  puts divide(10, 0)
rescue ArgumentError => e
  puts e.message
ensure
  puts "Division attempted"
end
</code></pre>

### Custom exceptions

Define your own by inheriting from `StandardError`:

<pre class="language-ruby"><code class="language-ruby">
class ServiceError &lt; StandardError; end

  raise ServiceError, &quot;Remote API unavailable&quot;
</code></pre>

### Practice checklist

- [ ] Wrap a file read in `begin`/`rescue` to catch `Errno::ENOENT` and print a friendly message.
- [ ] Use `ensure` to close a file handle even when an exception occurs.
- [ ] Define a custom exception and raise it from a validation method.
- [ ] Experiment with `retry` (inside `rescue`) to re-run the block after handling an error--use cautiously!

Next: keep iterating through Flow Control & Collections, now with robust error handling.

#### Practice 1 - Rescuing Errno::ENOENT

<p><strong>Goal:</strong> Wrap a file read in `begin`/`rescue` to catch `Errno::ENOENT` and print a friendly message.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-exceptions"
     data-practice-index="0"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('Errno::ENOENT') } && lines.any? { |l| l.downcase.include?('missing') }"><code class="language-ruby">
# TODO: Print a begin/rescue example that rescues Errno::ENOENT around
# a File.read call and prints a friendly message.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-exceptions"
     data-practice-index="0"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-exceptions:0">
puts "begin"
puts "  File.read('missing.txt')"
puts "rescue Errno::ENOENT"
puts "  puts 'Missing file; please create missing.txt'"
puts "end"
</script>

#### Practice 2 - Using ensure to close files

<p><strong>Goal:</strong> Show how `ensure` runs even when an exception occurs, to close a file handle.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-exceptions"
     data-practice-index="1"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('ensure') }"><code class="language-ruby">
# TODO: Print a begin/rescue/ensure block that opens a file and
# guarantees some cleanup work in ensure.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-exceptions"
     data-practice-index="1"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-exceptions:1">
puts "begin"
puts "  f = File.open('data.txt', 'r')"
puts "  # work with f"
puts "rescue => e"
puts "  puts \"Error: \#{e.message}\""
puts "ensure"
puts "  f.close if f && !f.closed?"
puts "end"
</script>

#### Practice 3 - Custom exceptions

<p><strong>Goal:</strong> Define a custom exception and raise it from a validation method.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-exceptions"
     data-practice-index="2"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('class InvalidDataError') } && lines.any? { |l| l.downcase.include?('raise') }"><code class="language-ruby">
# TODO: Print a small custom exception class and a validation method
# that raises it when data is invalid.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-exceptions"
     data-practice-index="2"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-exceptions:2">
puts "class InvalidDataError < StandardError; end"
puts "def validate!(value)"
puts "  raise InvalidDataError, 'value must be positive' if value <= 0"
puts "end"
</script>

#### Practice 4 - retry with caution

<p><strong>Goal:</strong> Experiment with `retry` inside `rescue` to re-run a block after handling an error.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-exceptions"
     data-practice-index="3"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('retry') }"><code class="language-ruby">
# TODO: Print a small example that uses retry inside a rescue clause,
# with a guard to avoid infinite loops.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-exceptions"
     data-practice-index="3"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-exceptions:3">
puts "attempts = 0"
puts "begin"
puts "  attempts += 1"
puts "  raise 'boom' if attempts < 2"
puts "rescue => e"
puts "  retry if attempts < 3"
puts "end"
</script>
