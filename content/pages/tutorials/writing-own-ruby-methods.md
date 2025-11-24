---
layout: tutorial
title: "Chapter 12 &ndash; Writing Your Own Ruby Methods"
permalink: /tutorials/writing-own-ruby-methods/
difficulty: beginner
summary: Define reusable Ruby methods, add default and variable arguments, use interpolation, and alias older implementations.
previous_tutorial:
  title: "Chapter 11: More on Ruby Methods"
  url: /tutorials/more-on-ruby-methods/
next_tutorial:
  title: "Chapter 13: Ruby `ri` Tool"
  url: /tutorials/ruby-ri-tool/
related_tutorials:
  - title: "Methods & blocks"
    url: /tutorials/methods-and-blocks/
  - title: "Ruby Names"
    url: /tutorials/ruby-names/
---

> Adapted from Satish Talim's "Writing Own Ruby Methods" lesson.

Defining a method is as simple as wrapping logic between `def` and `end`. The last evaluated expression becomes the return value, so you rarely need an explicit `return`.

### Basic method shapes

```ruby-exec
# p008mymethods.rb
# Methods that act as queries often end with ?
# Bang methods (!) signal a dangerous or mutating variant

def hello
  "Hello"
end

def hello1(name)
  "Hello #{name}"
end

def hello2 name # parentheses optional
  "Hello #{name}"
end

puts hello
puts hello1("Satish")
puts hello2 "Talim"
```

### Default arguments and interpolation

Ruby lets you set default values so callers can omit arguments:

```ruby-exec
# p009mymethods1.rb
def mtd(arg1="Dibya", arg2="Shashank", arg3="Shashank")
  "#{arg1}, #{arg2}, #{arg3}."
end

puts mtd
puts mtd("Ruby")
```

Interpolation (`#{ ... }`) evaluates the expression and inserts the result into the surrounding string:

```ruby-exec
puts "100 * 5 = #{100 * 5}"  # => 100 * 5 = 500
```

Ruby still lacks a way to skip the first argument and only override later ones, so order matters.

### Aliasing methods

Use `alias new_name old_name` to keep the original implementation before redefining it:

```ruby-exec
# p010aliasmtd.rb
def oldmtd
  "old method"
end

alias newmtd oldmtd

def oldmtd
  "old improved method"
end

puts oldmtd   # => "old improved method"
puts newmtd   # => "old method"
```

Aliases reference a copy of the original method body, so the new name keeps the old behavior even after redefinition.

### Variable arguments (`*args`)

The splat operator collects any number of arguments into an array:

```ruby-exec
# p011vararg.rb
def foo(*values)
  values.inspect
end

puts foo("hello", "world")  # ["hello", "world"]
puts foo                     # []
```

You can mix splats with required parameters--Ruby pushes arguments left-to-right--so defaults can reference earlier values:

```ruby-exec
# p012mtdstack.rb
def mtd(a = 99, b = a + 1)
  [a, b]
end

puts mtd.inspect  # [99, 100]
```

### Mutating arguments

Choose whether your methods mutate the objects you receive:

```ruby-exec
def downer(str)
  str.downcase
end

name = "HELLO"
downer(name)
puts name  # HELLO (original unchanged)

def downer!(str)
  str.downcase!
end

downer!(name)
puts name  # hello (mutated)
```

Following Ruby conventions, the bang version (`downer!`) makes the destructive behavior explicit.

### Practice checklist

- [ ] Create a method that greets users with optional arguments for first and last name; confirm defaults kick in when omitted.
- [ ] Alias a helper method, redefine the original, and ensure both behaviors remain available.
- [ ] Write a `log(*messages)` method that joins an arbitrary number of arguments and prints them.
- [ ] Experiment with pure vs bang-style methods to see how mutating arguments affects callers.

Next: move into Flow Control & Collections to loop over data with the methods you've authored.

#### Practice 1 - Greeting with optional arguments

**Goal:** Create a method that greets users with optional first and last name arguments.

#> ruby :practice

# TODO: Define greet(first = \"Guest\", last = nil) and print at least
# one greeting that uses defaults and one that passes both names.

```solution
def greet(first = "Guest", last = nil)
  name = [first, last].compact.join(" ").strip
  name = "Guest" if name.empty?
  "Hello, #{name}"
end

puts greet
puts greet("Ruby", "Learner")
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('Hello, Guest') } && lines.any? { |l| l.include?('Hello, Ruby Learner') }
```

#!


#### Practice 2 - Aliasing and redefining methods

**Goal:** Alias a helper method, redefine the original, and ensure both behaviours remain available.

#> ruby :practice

# TODO: Sketch a method, alias it, then redefine the original while
# the alias retains the earlier behaviour.

```solution
def hello
  "hi"
end

alias old_hello hello

def hello
  "hello"
end

puts "old: #{old_hello}"
puts "new: #{hello}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('old:') } && lines.any? { |l| l.include?('new:') }
```

#!


#### Practice 3 - Variadic log(*messages)

**Goal:** Write a `log(*messages)` method that joins an arbitrary number of arguments and prints them.

#> ruby :practice

# TODO: Define log(*messages) to join its arguments with spaces and
# print a single line.

```solution
def log(*messages)
  puts "log: #{messages.join(' ')}"
end

log("ruby")
log("write", "tests", "daily")
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.count { |l| l.downcase.start_with?('log:') } >= 2
```

#!


#### Practice 4 - Pure vs bang-style methods

**Goal:** Experiment with pure vs bang-style methods to see how mutating arguments affects callers.

#> ruby :practice

# TODO: Print a small example of a pure helper that returns a new
# value and a bang-style helper that mutates an argument.

```solution
def pure_upcase(str)
  str.upcase
end

def bang_upcase!(str)
  str.upcase!
end

word = "ruby"

puts "pure: #{pure_upcase(word)} (original: #{word})"
bang_upcase!(word)
puts "bang!: #{word}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('pure:') } && lines.any? { |l| l.include?('bang!') }
```

#!
