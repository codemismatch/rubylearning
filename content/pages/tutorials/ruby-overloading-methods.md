---
layout: tutorial
title: 'Chapter 31 &ndash; "Overloading" Methods the Ruby Way'
permalink: /tutorials/ruby-overloading-methods/
difficulty: intermediate
summary: Ruby doesn't have compile-time overloading, but optional args, splats, and keyword args give you flexible interfaces.
previous_tutorial:
  title: "Chapter 30: Overriding Methods"
  url: /tutorials/ruby-overriding-methods/
next_tutorial:
  title: "Chapter 32: Ruby Access Control"
  url: /tutorials/ruby-access-control/
related_tutorials:
  - title: "Writing Our Own Class"
    url: /tutorials/writing-our-own-class/
  - title: "Ruby Procs & Lambdas"
    url: /tutorials/ruby-procs/
---

> Adapted from Satish Talim's "Overloading Methods" lesson.

Ruby doesn't support traditional method overloading (same name, different signatures). Instead, you build flexible interfaces with default values, splats (`*args`), keyword arguments, and runtime dispatch.

### Optional and default arguments

```ruby-exec
def greet(name = "friend")
  "Hello, #{name}!"
end

puts greet          #=> "Hello, friend!"
puts greet("Satish") #=> "Hello, Satish!"
```

### Variable arguments with `*args`

```ruby-exec
def sum(*numbers)
  numbers.inject(0, :+)
end

puts sum            #=> 0
puts sum(1, 2, 3)   #=> 6
```

You can inspect `numbers.length` or the class of each argument to branch as needed.

### Keyword arguments

```ruby-exec
def send_email(to:, subject:, body: "Hello")
  # ...
end

send_email(to: "team@example.com", subject: "Reminder")
```

Keyword args make call sites self-documenting and avoid argument-order bugs.

### Tips from the legacy lesson

- Lean on Ruby's dynamic nature: check `args.length`, `args.first`, or presence of options to determine behavior.
- Don't overdo it--too many code paths in a single method can get confusing. Prefer separate methods if behavior differs significantly.
- Consider using hashes (`options = {}`) or keyword arguments for clarity when mimicking overloads.

### Practice checklist

- [ ] Write a `log(message, level = :info)` method and call it with/without the second argument.
- [ ] Build a `rectangle_area(*args)` method that accepts either two numbers (`width`, `height`) or a hash (`width:`, `height:`).
- [ ] Use keyword arguments with defaults to simulate constructor overloading in a small class.
- [ ] Inspect `args.length` in a method and raise `ArgumentError` when the combination doesn't make sense.

Next: keep applying these dynamic dispatch techniques inside Flow Control & Collections.

#### Practice 1 - log with optional level

**Goal:** Write a `log(message, level = :info)` method and call it with/without the second argument.

#> ruby :practice

# TODO: Define log(message, level = :info) and print a line showing
# both the default and an explicit level being used.

```solution
puts "def log(message, level = :info)"
puts "  puts \"[\#{level}] \#{message}\""
puts "end"
puts "log('hello')"
puts "log('danger', :error)"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('level=:info') }
```

#!


#### Practice 2 - rectangle_area with *args

**Goal:** Build `rectangle_area(*args)` that accepts either two numbers or a hash of options.

#> ruby :practice

# TODO: Sketch a rectangle_area(*args) implementation that accepts
# width/height as either positional args or a hash.

```solution
puts "def rectangle_area(*args)"
puts "  if args.first.is_a?(Hash)"
puts "    w = args.first.fetch(:width)"
puts "    h = args.first.fetch(:height)"
puts "  else"
puts "    w, h = args"
puts "  end"
puts "  w * h"
puts "end"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('rectangle_area') } && lines.any? { |l| l.downcase.include?('hash') }
```

#!


#### Practice 3 - Constructor keyword overloading

**Goal:** Use keyword arguments with defaults to simulate constructor overloading.

#> ruby :practice

# TODO: Print a small class whose initialize method uses keyword
# arguments with defaults to support multiple call styles.

```solution
puts "class User"
puts "  def initialize(name:, admin: false)"
puts "    @name = name"
puts "    @admin = admin"
puts "  end"
puts "end"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('initialize(') } && lines.any? { |l| l.include?('**opts') || l.include?('name:') }
```

#!


#### Practice 4 - Argument validation with ArgumentError

**Goal:** Inspect `args.length` in a method and raise `ArgumentError` when the combination doesn't make sense.

#> ruby :practice

# TODO: Print an example of checking args.length and raising
# ArgumentError for unsupported combinations.

```solution
puts "def overloaded(*args)"
puts "  raise ArgumentError, 'expected 1 or 2 args' unless [1, 2].include?(args.length)"
puts "end"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('ArgumentError') } && lines.any? { |l| l.include?('args.length') }
```

#!

