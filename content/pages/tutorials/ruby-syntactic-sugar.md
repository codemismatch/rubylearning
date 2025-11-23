---
layout: tutorial
title: "Chapter 37 &ndash; Ruby Syntactic Sugar"
permalink: /tutorials/ruby-syntactic-sugar/
difficulty: beginner
summary: Lean on Ruby's shorthand--attr helpers, literal shortcuts, and inline modifiers--to write expressive code.
previous_tutorial:
  title: "Chapter 36: Duck Typing"
  url: /tutorials/duck-typing/
next_tutorial:
  title: "Chapter 38: Mutable vs Immutable Objects"
  url: /tutorials/mutable-and-immutable-objects/
related_tutorials:
  - title: "Ruby Open Classes"
    url: /tutorials/ruby-open-classes/
  - title: "Ruby Overloading Methods"
    url: /tutorials/ruby-overloading-methods/
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
puts "Hello" if logged_in?
retry_count += 1 while retry_needed?
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

# TODO: Print a small class definition before/after showing how
# attr_accessor replaces handwritten getter/setter methods.

```solution
puts "class User"
puts "  attr_accessor :name"
puts "end"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('attr_accessor') }
```

#!


#### Practice 2 - Using %w for arrays of strings

**Goal:** Use `%w` to rewrite an array of strings without repetitive quotes.

#> ruby :practice

# TODO: Print an array of string literals, then show the equivalent
# using %w.

```solution
puts 'names = ["ann", "bob", "carla"]'
puts 'names = %w[ann bob carla]'
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('%w[') }
```

#!


#### Practice 3 - Inline if modifier

**Goal:** Convert a multi-line `if` to an inline modifier where readability improves.

#> ruby :practice

# TODO: Print a before/after example where a single-line action with
# an if modifier reads more cleanly than a full if/end block.

```solution
puts 'notify_admin if user.admin?'
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('if user.admin?') }
```

#!


#### Practice 4 - Implementing << in a custom class

**Goal:** Implement `<<` in a custom class to append items.

#> ruby :practice

# TODO: Print a class that defines << to append values to an internal
# array, returning self for chaining.

```solution
puts "class Bag"
puts "  def initialize"
puts "    @items = []"
puts "  end"
puts "  def <<(item)"
puts "    @items << item"
puts "    self"
puts "  end"
puts "end"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('def <<') }
```

#!

