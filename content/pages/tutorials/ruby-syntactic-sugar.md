---
layout: tutorial
title: "Chapter 37 &ndash; Ruby Syntactic Sugar"
permalink: /courses/ruby-basics/ruby-syntactic-sugar/
difficulty: beginner
summary: Lean on Ruby's shorthand--attr helpers, literal shortcuts, and inline modifiers--to write expressive code.
previous_tutorial:
  title: "Chapter 36: Duck Typing"
  url: /courses/ruby-basics/duck-typing/
next_tutorial:
  title: "Chapter 38: Mutable vs Immutable Objects"
  url: /courses/ruby-basics/mutable-and-immutable-objects/
related_tutorials:
  - title: "Ruby Open Classes"
    url: /courses/ruby-basics/ruby-open-classes/
  - title: "Ruby Overloading Methods"
    url: /courses/ruby-basics/ruby-overloading-methods/
---

> Adapted from Satish Talim's "Ruby Syntactic Sugar" notes.

Ruby's syntax hides repetitive boilerplate so you can focus on intent.

### attr_* helpers

```ruby-exec
class Person
  attr_accessor :name, :email
end
```

This expands to getter/setter methods--no need to write them manually.

### Operator methods

`a + b` is shorthand for `a.+(b)`. Many operators are method calls, so you can override them when needed (`<<`, `[]`, etc.).

### Inline modifiers

```ruby-exec
def logged_in?
  true
end

def retry_needed?(count)
  count < 3
end

retry_count = 0

puts "Hello" if logged_in?
retry_count += 1 while retry_needed?(retry_count)
puts "Retries: #{retry_count}"
```

Single-line conditionals keep intent obvious.

### Literal shortcuts

- `%w[foo bar]` -> `["foo", "bar"]`
- `%i[foo bar]` -> `[:foo, :bar]`
- Symbol hash keys: `{ nickname: "Satish", language: "Marathi" }`
- Ranges: `1..5` (inclusive), `1...5` (exclusive)

### Practice checklist

- [ ] Replace manual getters/setters with `attr_accessor`.
- [ ] Use `%w` to rewrite an array of strings without repetitive quotes.
- [ ] Convert a multi-line `if` to an inline modifier where readability improves.
- [ ] Implement `<<` in a custom class to append items and see how operator methods feel.

Next: continue through Flow Control & Collections, now armed with concise Ruby idioms.

#### Practice 1 - Replacing manual getters/setters

**Goal:** Replace manual getter/setter methods with `attr_accessor`.

#> ruby :practice

# TODO: Show how attr_accessor replaces handwritten getter/setter methods.

```solution
class User
  attr_accessor :name
end

user = User.new
user.name = "Alice"
puts "Name: #{user.name}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('Name: Alice') }
```

#!


#### Practice 2 - Using %w for arrays of strings

**Goal:** Use `%w` to rewrite an array of strings without repetitive quotes.

#> ruby :practice

# TODO: Use %w to create an array of strings without repetitive quotes.

```solution
# Traditional way
names1 = ["ann", "bob", "carla"]

# Using %w syntactic sugar
names2 = %w[ann bob carla]

puts "Traditional: #{names1.inspect}"
puts "With %w: #{names2.inspect}"
puts "Equal: #{names1 == names2}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('With %w:') } && lines.any? { |l| l.include?('Equal: true') }
```

#!


#### Practice 3 - Inline if modifier

**Goal:** Convert a multi-line `if` to an inline modifier where readability improves.

#> ruby :practice

# TODO: Show an inline if modifier example.

```solution
user_admin = true

# Multi-line version
if user_admin
  puts "Admin access granted"
end

# Inline modifier version (more concise)
puts "Admin access granted" if user_admin
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.count { |l| l.include?('Admin access granted') } >= 2
```

#!


#### Practice 4 - Implementing << in a custom class

**Goal:** Implement `<<` in a custom class to append items.

#> ruby :practice

# TODO: Define a class that implements << to append items, returning self for chaining.

```solution
class Bag
  def initialize
    @items = []
  end
  
  def <<(item)
    @items << item
    self
  end
  
  def items
    @items
  end
end

bag = Bag.new
bag << "apple" << "banana" << "cherry"
puts "Items: #{bag.items.inspect}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('Items:') } && lines.any? { |l| l.include?('apple') }
```

#!
