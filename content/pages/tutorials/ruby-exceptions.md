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
