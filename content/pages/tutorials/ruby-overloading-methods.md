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
def log(message, level = :info)
  puts "[#{level}] #{message}"
end

log("hello")
log("danger", :error)
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('[info] hello') } && lines.any? { |l| l.include?('[error] danger') }
```

#!


#### Practice 2 - rectangle_area with *args

**Goal:** Build `rectangle_area(*args)` that accepts either two numbers or a hash of options.

#> ruby :practice

# TODO: Sketch a rectangle_area(*args) implementation that accepts
# width/height as either positional args or a hash.

```solution
def rectangle_area(*args)
  if args.first.is_a?(Hash)
    options = args.first
    width = options.fetch(:width)
    height = options.fetch(:height)
  else
    width, height = args
  end

  width * height
end

puts "area (positional): #{rectangle_area(4, 5)}"
puts "area (hash): #{rectangle_area(width: 2, height: 6)}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('area (positional): 20') } && lines.any? { |l| l.include?('area (hash): 12') }
```

#!


#### Practice 3 - Constructor keyword overloading

**Goal:** Use keyword arguments with defaults to simulate constructor overloading.

#> ruby :practice

# TODO: Print a small class whose initialize method uses keyword
# arguments with defaults to support multiple call styles.

```solution
class User
  def initialize(name:, admin: false)
    @name = name
    @admin = admin
  end

  def info
    "User #{@name}, admin=#{@admin}"
  end
end

puts User.new(name: "Ruby").info
puts User.new(name: "Satish", admin: true).info
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('admin=false') } && lines.any? { |l| l.include?('admin=true') }
```

#!


#### Practice 4 - Argument validation with ArgumentError

**Goal:** Inspect `args.length` in a method and raise `ArgumentError` when the combination doesn't make sense.

#> ruby :practice

# TODO: Print an example of checking args.length and raising
# ArgumentError for unsupported combinations.

```solution
def overloaded(*args)
  raise ArgumentError, "expected 1 or 2 args" unless [1, 2].include?(args.length)
  args.join(", ")
end

puts "call with 1 arg: #{overloaded('only')}"

begin
  overloaded
rescue ArgumentError => e
  puts "Raised ArgumentError: #{e.message}"
end
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('call with 1 arg') } && lines.any? { |l| l.include?('Raised ArgumentError') }
```

#!
