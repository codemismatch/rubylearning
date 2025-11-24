---
layout: tutorial
title: "Chapter 6 &ndash; Fun with Strings"
permalink: /tutorials/fun-with-strings/
difficulty: beginner
author: Pankaj Doharey
summary: Explore Ruby's flexible string literals, concatenation tricks, interpolation, and shell-friendly backticks before moving on to control flow.
previous_tutorial:
  title: "Chapter 5: Numbers in Ruby"
  url: /tutorials/numbers-in-ruby/
next_tutorial:
  title: "Chapter 7: Variables & Assignment"
  url: /tutorials/variables-and-assignment/
related_tutorials:
  - title: "Ruby Features"
    url: /tutorials/ruby-features/
  - title: "Flow control & collections"
    url: /tutorials/flow-control-collections/
---

> Adapted from Satish Talim's "Fun with Strings" lesson on RubyLearning, refreshed with modern Ruby notes.

Strings are sequences of characters surrounded by quotes. Ruby treats both single (`'`) and double (`"`) quotes as literal delimiters, and even the empty string (`''`) is a real object you can pass around.

### Warm up with a string script

Here's a modernised take on `p003rubystrings.rb`, highlighting concatenation, escaping, repetition, and constants:

```ruby-exec
# frozen_string_literal: true

puts "Hello World"
puts 'Hello World'             # same result, but no interpolation
puts 'I like' + ' Ruby'        # concatenation
puts 'Hello ' * 3              # repetition
puts 'It\s my Ruby'           # escape quotes

PI = 3.1416
puts PI
```

Key takeaways:

- `puts` converts non-string objects with `to_s` before printing.
- Literal strings are mutable by default. Freeze them globally with `# frozen_string_literal: true` and unfreeze selectively via `+`prefix or `.dup`.
- Double-quoted strings support interpolation (`"Hi #{name}"`) and backslash escape sequences; single quotes keep content literal except for `\\` and `\'`.

### Command substitution with backticks

Backticks run shell commands and return their output as a string. The result still flows through Ruby, so you can print it, split it, or test it.

```ruby-exec
puts `ls`   # macOS/Linux: directory listing
puts `dir`  # Windows: directory listing
```

Ruby also exposes `Kernel#system` when you simply need to execute a command and check success:

```ruby-exec
if system("tar xzf data.tgz")
  puts "Archive extracted"
else
  warn "Extraction failed"
end
```

`system` returns `true` when the command exits successfully, `false` when it runs but fails, and `nil` if the command is missing.

### Practice checklist

- [ ] Recreate the sample script and add interpolation (`"Hello #{ENV['USER']}"`) plus concatenation to see both approaches.
- [ ] Freeze string literals at the top of a file and experiment with `+` and `.dup` to control mutability.
- [ ] Capture the output of `` `ruby -v` `` into a variable and parse the version number.
- [ ] Use `system` to run a harmless command (like `echo Done`) and branch on the return value.
	
#### Practice 1 - Interpolation and concatenation

**Goal:** Print two greeting lines using both interpolation and concatenation.

#> ruby :practice

# TODO: Write Ruby code that prints at least two greeting lines.
# Hint:
#   - Use string interpolation for one line: "Hello #{name}"
#   - Use string concatenation for another: "Hello " + name
#   - Try using ENV["USER"] or a hard-coded name.

```solution
name = ENV["USER"] || "Rubyist"

puts "Hello #{name}"        # interpolation
greeting = "Hello " + name  # concatenation
puts greeting
```

```test
out = output.string; lines = out.lines.map(&:strip).reject(&:empty?); lines.size >= 2 && lines.all? { |l| l.include?('Hello') }
```

#!


#### Practice 2 - Freezing and dup

**Goal:** Show two different strings derived from the same frozen base literal.

#> ruby :practice

# TODO: Start from a frozen string literal and produce two *different* strings.
# Hint:
#   - Use `base = "hello"` with `# frozen_string_literal: true`.
#   - Use `base + " world!"` for one result.
#   - Use `base.dup` and `<<` for another.
#   - Print both results so they appear on separate lines.

```solution
base = "hello"

with_world = base + " world!"

copy = base.dup
copy << " from Ruby"

puts with_world
puts copy
```

```test
out = output.string; lines = out.lines.map(&:strip).reject(&:empty?); lines.include?('hello world!') && lines.include?('hello from Ruby')
```

#!


#### Practice 3 - Parsing a version string

**Goal:** Extract the Ruby version number from a version string.

#> ruby :practice

# Simulated output from `ruby -v`
version_output = "ruby 3.3.0p0 (2024-01-01 revision 12345) [arm64-darwin23]"

# TODO:
#   - Extract just the version number (e.g. 3.3.0) into `version`.
#   - Print both the full string and the parsed version.
# Hint: a regex like `/ruby\s+([\d.]+)/` can capture the version.

```solution
version_output = "ruby 3.3.0p0 (2024-01-01 revision 12345) [arm64-darwin23]"

version = version_output[/ruby\s+([\d.]+)/, 1]

puts "Full:   #{version_output.strip}"
puts "Parsed: #{version}"  # expecting: Parsed: 3.3.0
```

```test
out = output.string; out.include?('Parsed: 3.3.0')
```

#!


#### Practice 4 - Branching on command success

**Goal:** Simulate a system command and branch based on its success.

#> ruby :practice

# In a real script you might call: system("echo Done")
# Here we'll simulate the result with a boolean flag.

# TODO:
#   - Set `command_succeeded` to true or false.
#   - Print a different message for success vs failure.
# Hint: follow the structure of an if/else that prints a checkmark on success.

```solution
command_succeeded = true  # change to false to test the other branch

if command_succeeded
  puts "Command succeeded"
else
  puts "Command failed"
end
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('Command succeeded') || l.include?('Command failed') }
```

#!


Next up: apply what you know about numbers and strings while branching through Flow Control & Collections.
