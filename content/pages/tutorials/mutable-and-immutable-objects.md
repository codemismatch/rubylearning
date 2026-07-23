---
layout: tutorial
title: "Chapter 38 &ndash; Mutable vs Immutable Objects"
permalink: /courses/ruby-basics/mutable-and-immutable-objects/
difficulty: beginner
summary: Know which Ruby objects change in place (strings, arrays) and which do not (numbers, symbols), and how `freeze` locks state.
previous_tutorial:
  title: "Chapter 37: Ruby Syntactic Sugar"
  url: /courses/ruby-basics/ruby-syntactic-sugar/
next_tutorial:
  title: "Chapter 39: Object Serialization (Marshal)"
  url: /courses/ruby-basics/object-serialization/
related_tutorials:
  - title: "Ruby Symbols"
    url: /courses/ruby-basics/ruby-symbols/
  - title: "Ruby Open Classes"
    url: /courses/ruby-basics/ruby-open-classes/
---

> Adapted from Satish Talim's "Mutable and Immutable Objects" lesson.

Ruby stores some objects as mutable containers (strings, arrays, hashes) and others as immutable values (numbers, symbols). Understanding the difference prevents surprises when multiple variables reference the same object.

### Mutable example: strings

```ruby-exec
name = "Ruby"
copy = name

name.upcase!
puts copy  #=> "RUBY"
```

`alias` changed because both variables point to the same mutable string object.

### Immutable example: numbers

```ruby-exec
count = 10
other = count

count += 5
puts other  #=> 10
```

Numeric literals are immutable immediate values; arithmetic always returns a new object.

### Symbols are immutable

Symbols are allocated once and never modified:

```ruby-exec
status = :ok
# :ok is frozen automatically; no bang methods mutate it
```

### Freezing objects

Call `freeze` to prevent further modification:

```ruby-exec
config = { retries: 3 }.freeze
config[:timeout] = 10  # raises FrozenError
```

Frozen strings are common when `# frozen_string_literal: true` appears at the top of a file.

### Practice checklist

- [ ] Demonstrate how two arrays referencing the same object both mutate after `<<`.
- [ ] Freeze a string and rescue the `FrozenError` raised when attempting to append to it.
- [ ] Explain why symbol keys in hashes don't need cloning--they're immutable.
- [ ] Use `dup` to copy a mutable object before modifying it.

Next: continue into Flow Control & Collections, now mindful of which objects mutate in place.

#### Practice 1 - Shared references and mutation

**Goal:** Show how two arrays referencing the same object mutate together after `<<`.

#> ruby :practice

# TODO: Create one array, assign it to two variables, push a value via
# one variable, and print both before and after to show they point to
# the same object.

```solution
nums = [1, 2]
alias_ref = nums

puts "before: nums=#{nums.inspect}, alias_ref=#{alias_ref.inspect}"

nums << 3

puts "after:  nums=#{nums.inspect}, alias_ref=#{alias_ref.inspect}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('before:') } && lines.any? { |l| l.downcase.include?('after:') }
```

#!


#### Practice 2 - Freezing and FrozenError

**Goal:** Freeze a string and rescue the `FrozenError` when appending to it.

#> ruby :practice

# TODO: Freeze a string and attempt to append to it, rescuing the
# FrozenError and printing a short message.

```solution
greeting = "hello".freeze

begin
  greeting << " world"
rescue FrozenError => e
  puts "Caught FrozenError: #{e.message}"
ensure
  puts "String frozen? #{greeting.frozen?}"
end
```

```test
out = output.string
out.include?('Caught FrozenError') && out.include?('String frozen? true')
```

#!


#### Practice 3 - Immutable symbol keys

**Goal:** Explain why symbol keys in hashes don't need cloning.

#> ruby :practice

# TODO: Create a hash with symbol keys, access them, and print a
# sentence noting that symbols are immutable and reused, so the keys
# don't need cloning.

```solution
person = { name: "Rubyist", city: "Pune" }
symbol_id = :name.object_id

puts "Keys: #{person.keys.inspect}"
puts "name: #{person[:name]}"
puts "Symbol object_id stable? #{symbol_id == :name.object_id}"
puts "Symbols are immutable and reused, so hash keys like :name don't need cloning."
```

```test
out = output.string
out.include?('Symbol object_id stable? true') && out.downcase.include?('immutable')
```

#!


#### Practice 4 - Duplicating before modifying

**Goal:** Use `dup` to copy a mutable object before modifying it.

#> ruby :practice

# TODO: Start with a single array or string, create a dup, mutate the
# copy, and print both original and copy to show only the copy changed.

```solution
original = [1, 2, 3]
copy = original.dup

copy << 4

puts "original: #{original.inspect}"
puts "copy:     #{copy.inspect}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('original:') } && lines.any? { |l| l.downcase.include?('copy:') }
```

#!
