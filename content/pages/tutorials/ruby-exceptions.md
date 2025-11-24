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

```ruby-exec
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
```

- `rescue SpecificError => e` lets you branch per exception type.
- `else` executes only when no exception was raised.
- `ensure` runs regardless of success or failure--perfect for closing files or releasing resources.

### Raising exceptions

`raise` (alias `fail`) triggers an exception:

```ruby-exec
raise "Something went wrong"
raise ArgumentError, "Bad argument"
raise ArgumentError.new("Bad argument")
```

Calling `raise` with no arguments inside `rescue` re-raises the current exception.

### Legacy example

```ruby-exec
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
```

### Custom exceptions

Define your own by inheriting from `StandardError`:

```ruby-exec
class ServiceError < StandardError; end

  raise ServiceError, "Remote API unavailable"
```

### Practice checklist

- [ ] Wrap a file read in `begin`/`rescue` to catch `Errno::ENOENT` and print a friendly message.
- [ ] Use `ensure` to close a file handle even when an exception occurs.
- [ ] Define a custom exception and raise it from a validation method.
- [ ] Experiment with `retry` (inside `rescue`) to re-run the block after handling an error--use cautiously!

Next: keep iterating through Flow Control & Collections, now with robust error handling.

#### Practice 1 - Rescuing Errno::ENOENT

**Goal:** Wrap a file read in `begin`/`rescue` to catch `Errno::ENOENT` and print a friendly message.

#> ruby :practice

# TODO: Print a begin/rescue example that rescues Errno::ENOENT around
# a File.read call and prints a friendly message.

```solution
begin
  File.read("missing.txt")
rescue Errno::ENOENT
  puts "Missing file; please create missing.txt"
end
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('missing file') }
```

#!


#### Practice 2 - Using ensure to close files

**Goal:** Show how `ensure` runs even when an exception occurs, to close a file handle.

#> ruby :practice

# TODO: Print a begin/rescue/ensure block that opens a file and
# guarantees some cleanup work in ensure.

```solution
path = "ensure-demo.txt"
File.write(path, "temporary line\n")

file = nil

begin
  file = File.open(path, "r")
  puts file.readline.strip
  raise "simulated failure"
rescue => e
  puts "Error: #{e.message}"
ensure
  if file && !file.closed?
    file.close
    puts "File closed in ensure"
  end
  File.delete(path) if File.exist?(path)
end
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('file closed') }
```

#!


#### Practice 3 - Custom exceptions

**Goal:** Define a custom exception and raise it from a validation method.

#> ruby :practice

# TODO: Print a small custom exception class and a validation method
# that raises it when data is invalid.

```solution
class InvalidDataError < StandardError; end

def validate!(value)
  raise InvalidDataError, "value must be positive" if value <= 0
  true
end

begin
  validate!(-1)
rescue InvalidDataError => e
  puts "Validation failed: #{e.message}"
end
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('Validation failed') }
```

#!


#### Practice 4 - retry with caution

**Goal:** Experiment with `retry` inside `rescue` to re-run a block after handling an error.

#> ruby :practice

# TODO: Print a small example that uses retry inside a rescue clause,
# with a guard to avoid infinite loops.

```solution
attempts = 0

begin
  attempts += 1
  puts "Attempt ##{attempts}"
  raise "boom" if attempts < 2
rescue => e
  puts "Rescued: #{e.message}"
  retry if attempts < 3
end
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('Attempt') } && lines.any? { |l| l.include?('Rescued') }
```

#!
