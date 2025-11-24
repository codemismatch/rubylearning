---
layout: tutorial
title: "Chapter 9 &ndash; Getting Input"
permalink: /tutorials/getting-input/
difficulty: beginner
summary: Read keyboard input with `gets`, tidy it up with `chomp`, and understand when to flush STDOUT for interactive prompts.
previous_tutorial:
  title: "Chapter 8: Scope"
  url: /tutorials/scope/
next_tutorial:
  title: "Chapter 10: Ruby Names"
  url: /tutorials/ruby-names/
related_tutorials:
  - title: "Variables & Assignment"
    url: /tutorials/variables-and-assignment/
  - title: "Ruby Features"
    url: /tutorials/ruby-features/
---

> Adapted from Satish Talim's original RubyLearning lesson on user input, refreshed for Typophic.

So far you've been printing output with `puts`. To make your scripts interactive you need to read input from the keyboard (standard input). Ruby ships the `gets` method for this and a companion `String#chomp` helper to trim trailing newlines.

### Sample prompt script

```ruby-exec
# p005methods.rb
# gets and chomp
puts "In which city do you stay?"
STDOUT.flush
city = gets.chomp
puts "The city is #{city}"
```

What's happening:

- `STDOUT` is the global constant for the program's standard output stream.
- `STDOUT.flush` forces Ruby to push any buffered output to the console immediately, ensuring the prompt appears before `gets` blocks. You can skip this if you set `STDOUT.sync = true` once, which enables auto-flushing.
- `gets` reads a line from standard input (the keyboard) and returns it as a string including the trailing newline.
- `chomp` removes the trailing newline so string concatenation/interpolation behaves as expected.

### Input sources in Rails land

Rails apps rarely call `gets` because web requests provide parameters and data comes from databases. Still, understanding Ruby's core IO helps when you write scripts, background jobs, or quick prototypes outside the request/response cycle.

### Practice checklist

- [ ] Modify the sample script to request both city and country, and print a combined sentence.
- [ ] Toggle `STDOUT.sync = true` at the top of your script and remove manual `flush` calls to see the effect.
- [ ] Capture numeric input (`gets.chomp.to_i`) and use it in a calculation.
- [ ] Experiment with piping data into your script (`echo "Pune" | ruby prompt.rb`) to see how standard input differs from keyboard typing.

Up next: move into Flow Control & Collections to react to the data you just gathered.

#### Practice 1 - Reading multiple text inputs

**Goal:** Request both city and country from the user and print a combined sentence.

#> ruby :practice

# TODO: Define a class method self.main that asks for city and country
# using gets.chomp and prints a single sentence including both values.
# Hint:
#   - The test harness will call sandbox.main with simulated input.

```solution
def self.main
  print "Which city do you live in? "
  city = (gets&.chomp).to_s

  print "Which country is that in? "
  country = (gets&.chomp).to_s

  puts "You live in #{city}, #{country}."
end
```

```test
result = false
if self.respond_to?(:main)
  require "stringio"
  original_stdin = $stdin
  $stdin = StringIO.new("London\nUnited Kingdom\n")
  begin
    self.main
  ensure
    $stdin = original_stdin
    singleton_class.send(:remove_method, :main) rescue nil
  end
  out = output.string.downcase
  result = out.include?('you live in') && !out.include?('null')
else
  output.puts("Define self.main to read input.")
end
result
```

#!

#### Practice 2 - Using STDOUT.sync

**Goal:** Toggle `STDOUT.sync = true` and rely on implicit flushing.

#> ruby :practice

# TODO: Define self.main to set STDOUT.sync = true, print a prompt
# without calling flush explicitly, read a value with gets, and then
# print a confirmation message.

```solution
def self.main
  STDOUT.sync = true

  print "Enter your name: "
  name = (gets&.chomp).to_s

  puts "STDOUT.sync is now true"
  puts "Hello, #{name}!"
end
```

```test
result = false
if self.respond_to?(:main)
  require "stringio"
  original_stdin = $stdin
  $stdin = StringIO.new("Typist\n")
  begin
    self.main
  ensure
    $stdin = original_stdin
    singleton_class.send(:remove_method, :main) rescue nil
  end
  out = output.string.downcase
  result = out.include?('stdout.sync') && out.include?('hello, typist')
else
  output.puts("Define self.main to toggle STDOUT.sync.")
end
result
```

#!

#### Practice 3 - Numeric input and calculations

**Goal:** Capture numeric input and use it in a calculation.

#> ruby :practice

# TODO: Define self.main to ask the user for a number, convert it to
# an integer, and use it in a simple calculation (for example,
# doubling it). Print the total.

```solution
def self.main
  print "How many lessons have you completed? "
  count = (gets&.chomp).to_i

  total = count * 2
  puts "Total: #{total}"
end
```

```test
result = false
if self.respond_to?(:main)
  require "stringio"
  original_stdin = $stdin
  $stdin = StringIO.new("5\n")
  begin
    self.main
  ensure
    $stdin = original_stdin
    singleton_class.send(:remove_method, :main) rescue nil
  end
  out = output.string.downcase
  result = out.include?('total:') && !out.include?('null')
else
  output.puts("Define self.main to read numeric input.")
end
result
```

#!

#### Practice 4 - Thinking about piped input

**Goal:** Experiment mentally with how piped input behaves compared to keyboard input.

#> ruby :practice

# TODO: Define self.main so it reads a single line from STDIN (which
# might come from a pipe) and prints a message that mentions piped
# input.

```solution
def self.main
  city = (gets&.chomp).to_s

  puts "Received city from piped input or keyboard: #{city.inspect}"
  puts "You could run: echo \"Pune\" | ruby prompt.rb"
end
```

```test
result = false
if self.respond_to?(:main)
  require "stringio"
  original_stdin = $stdin
  $stdin = StringIO.new("Pune\n")
  begin
    self.main
  ensure
    $stdin = original_stdin
    singleton_class.send(:remove_method, :main) rescue nil
  end
  out = output.string.downcase
  result = out.include?('piped input') || out.include?('piped')
else
  output.puts("Define self.main so it reads STDIN once.")
end
result
```

#!
