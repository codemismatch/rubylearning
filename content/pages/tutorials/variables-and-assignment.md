---
layout: tutorial
title: "Chapter 7 &ndash; Variables & Assignment"
permalink: /courses/ruby-basics/variables-and-assignment/
difficulty: beginner
summary: Learn how Ruby creates variables, distinguishes barewords from method calls, and converts between strings and numbers using everyday scripts.
previous_tutorial:
  title: "Chapter 6: Fun with Strings"
  url: /courses/ruby-basics/fun-with-strings/
next_tutorial:
  title: "Chapter 8: Scope"
  url: /courses/ruby-basics/scope/
related_tutorials:
  - title: "Ruby Features"
    url: /courses/ruby-basics/ruby-features/
  - title: "Numbers in Ruby"
    url: /courses/ruby-basics/numbers-in-ruby/
date: 2025-11-14
---

> Adapted from Satish Talim's original RubyLearning lesson on variables, modernised for this Typophic site.

When you *assign* a value, Ruby creates the variable on the fly:

```ruby-exec
s = "Hello World!"
x = 10
```

Ruby doesn't need a declaration keyword&mdash;the interpreter simply sees an assignment and allocates the variable.

### Barewords & local variables

A bareword is any unadorned identifier (letters, digits, underscores). Ruby interprets barewords in this order:

1. If an equals sign follows the bareword, it becomes a **local variable** receiving a value.
2. If it matches a reserved word, Ruby treats it as a **keyword** (e.g., `if`, `end`, `class`).
3. Otherwise, Ruby assumes it's a **method call** on the current object.

> Reference: <https://web.archive.org/web/20181219143329/http://alumnus.caltech.edu/~svhwan/prodScript/avoidBarewords.html> -- local variables and barewords share the same syntax, so prefer lowercase snake_case names and avoid Ruby keywords to keep intent clear.

```ruby-exec
def greeting
  "Hello!"
end

puts greeting        # method call (uses the method defined above)
answer = 42          # local variable assignment
class_name = "User"  # still a variable; keywords must be exact matches
```

Because method calls and barewords share syntax, name collisions can be confusing. Stick to snake_case for locals, avoid Ruby keywords, and favour descriptive verbs for methods.

### Constants, locals, and conversions

Satish's `p004stringusage.rb` script still makes a great tour of assignments:

```ruby-exec
# frozen_string_literal: true

PI = 3.1416              # constant: name starts with uppercase
puts PI

my_string = "I love my city, Pune"
puts my_string

var1 = 5
var2 = "2"
puts var1 + var2.to_i    # convert string to integer
```

Ruby ships with `.to_i`, `.to_f`, and `.to_s` on most core classes so you can convert as needed before combining values.

### Appending and here documents

Use the shovel operator `<<` to mutate a string in place:

```ruby-exec
message = "hello "
message << "world.\nI love this world..."
puts message
```

For multi-line strings, reach for a heredoc:

```ruby-exec
story = <<END_STR
 This is the string And a second line
END_STR

puts story
```

The line containing `END_STR` must be flush-left and match the opening identifier exactly.

### Messages, receivers, and dots

Method calls read as "send this **message** to that **receiver**." The dot connects the two:

```ruby-exec
x = "200.0".to_f
```

Here the string `"200.0"` is the receiver and `to_f` is the message. Ruby evaluates the expression on the left of the dot first, then calls the method named on the right.

### Practice checklist

- [ ] Write a script that assigns the same bareword both as a local (`status = "new"`) and as a method (`def status; "ok"; end`) to observe the precedence rules.
- [ ] Recreate `p004stringusage.rb` and extend it with `.to_s` and `.to_f` examples.
- [ ] Append to a string with `<<` and compare the result to concatenation with `+`.
- [ ] Define a heredoc that includes interpolation and confirm it respects the surrounding quotation style (`<<~` for indentation stripping is handy).

Next: put these variables to work while branching through Flow Control & Collections.

#### Practice 1 - Bareword precedence

**Goal:** Assign the same bareword as both a local and a method to observe precedence rules.

#> ruby :practice

# TODO: Print a snippet that assigns status = \"new\" and also defines
# def status; \"ok\"; end, then inspect which one is used where.

```solution
status = "new"

def status
  "ok"
end

puts "Local variable -> #{status}"
puts "Method call   -> #{status()}"
```

```test
out = output.string
lines = out.lines.map(&:strip)
lines.any? { |l| l.include?('Local variable ->') } &&
  lines.any? { |l| l.include?('Method call') }
```

#!


#### Practice 2 - Casting with to_s and to_f

**Goal:** Extend `p004stringusage.rb` with `.to_s` and `.to_f` examples.

#> ruby :practice

# TODO: Print a couple of conversions using to_s and to_f on numeric
# and string values.

```solution
number = 42
decimal_text = "3.14"

puts "Integer to string: #{number.to_s} (#{number.to_s.class})"
puts "String to float: #{decimal_text.to_f} (#{decimal_text.to_f.class})"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('Integer to string') } && lines.any? { |l| l.include?('String to float') }
```

#!


#### Practice 3 - << vs +

**Goal:** Append to a string with `<<` and compare the result to concatenation with `+`.

#> ruby :practice

# TODO: Show how << mutates a string while + returns a new string,
# printing both results.

```solution
greeting = "hi"

mutable = greeting.dup
mutable << " there"
puts "After << : #{mutable}"

combined = greeting + " there"
puts "Using + result: #{combined}"
puts "Original greeting after +: #{greeting}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('After <<') } && lines.any? { |l| l.include?('Using + result') }
```

#!


#### Practice 4 - Heredocs with interpolation

**Goal:** Define a heredoc that includes interpolation and respects quotation style.

#> ruby :practice

# TODO: Print a simple heredoc using <<~ that interpolates a variable.

```solution
name = "Ruby"

message = <<~TEXT
  Hello, #{name}!
  Welcome to heredocs.
TEXT

puts message
```

```test
out = output.string; out.include?('Hello, Ruby!')
```

#!
