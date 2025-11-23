---
layout: tutorial
title: "Chapter 20 &ndash; Ruby Hashes"
permalink: /tutorials/ruby-hashes/
difficulty: beginner
summary: Store key/value pairs with Ruby hashes, leverage symbols for efficient keys, and learn the literal syntaxes that keep your data tidy.
previous_tutorial:
  title: "Chapter 19: Ruby Symbols"
  url: /tutorials/ruby-symbols/
next_tutorial:
  title: "Chapter 21: Ruby Random Numbers"
  url: /tutorials/ruby-random-numbers/
related_tutorials:
  - title: "Ruby Symbols"
    url: /tutorials/ruby-symbols/
  - title: "Ruby Arrays"
    url: /tutorials/ruby-arrays/
---

> Adapted from Satish Talim's Ruby Hashes lesson.

Hashes (aka associative arrays, maps, dictionaries) pair any object as a **key** to any object as a **value**. Unlike arrays, which use integer indexes, hashes can use strings, symbols, regexes, numbers--anything that implements `hash` and `eql?`.

### Hash literals and access

```ruby-exec
# p040myhash.rb
h = { "dog" => "canine", "cat" => "feline", "donkey" => "asinine", 12 => "dodecine" }

puts h.length   # 4
puts h["dog"]   # canine
puts h[12]      # dodecine
puts h          # prints the whole hash
```

- Missing keys return `nil` unless you provide a default (`Hash.new("Unknown")`).
- Hashes are unordered prior to Ruby 1.9; newer Rubies preserve insertion order.

### Symbols as hash keys

Symbols make efficient, readable keys:

```ruby-exec
# p041symbolhash.rb
person = {}
person[:nickname] = "IndianGuru"
person[:language] = "Marathi"
person[:lastname] = "Talim"

puts person[:lastname] # Talim
```

Modern Ruby supports the JSON-style literal when keys are symbols:

```ruby-exec
# p0411symbolhash.rb
person = { :nickname => "IndianGuru", :language => "Marathi", :lastname => "Talim" }

# p0412symbolhash.rb
person = { nickname: "IndianGuru", language: "Marathi", lastname: "Talim" }
```

Both yield `{ :nickname=>"IndianGuru", :language=>"Marathi", :lastname=>"Talim" }`. The short `{ key: value }` syntax works only for symbol keys; use the hashrocket (`=>`) for strings, numbers, or other objects (`{ 1 => "one" }`).

### Defaults and lookup

```ruby-exec
counts = Hash.new(0)
counts[:apples] += 1
puts counts[:missing]  # 0 instead of nil
```

This pattern is handy for tallies and grouping. For nested hashes, consider `Hash.new { |h, k| h[k] = {} }`.

### Practice checklist

- [ ] Recreate `p040myhash.rb`, then set a default value to see how missing keys behave.
- [ ] Build a hash using the JSON-style literal and confirm it matches the hashrocket version.
- [ ] Refactor a string-keyed hash to use symbols and notice the improved readability.
- [ ] Experiment with non-symbol keys (numbers, arrays) to see how Ruby handles equality.

Next: with symbols and hashes under your belt, continue into Flow Control & Collections where these structures help drive iterators and data transformations.

#### Practice 1 - Hash defaults

**Goal:** Create a hash with a default value and observe missing keys.

#> ruby :practice

# TODO: Create a hash with a default value, access a missing key, and
# print the default along with the hash contents.

```solution
counts = Hash.new(0)
puts "default: #{counts[:missing]}"
counts[:apples] += 1
puts "hash: #{counts.inspect}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('default') } && lines.any? { |l| l.include?(':missing') }
```

#!


#### Practice 2 - JSON-style vs hashrocket

**Goal:** Build a hash using both JSON-style and hashrocket syntax and compare them.

#> ruby :practice

# TODO: Print two equivalent hashes, one using the newer symbol: value
# syntax and one using hashrockets, and demonstrate that they are equal.

```solution
json_style = { name: "Ruby", version: "3.3" }
rocket_style = { :name => "Ruby", :version => "3.3" }

puts "json-style:   #{json_style.inspect}"
puts "hashrockets:  #{rocket_style.inspect}"
puts "equal?: #{json_style == rocket_style}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('=>') } && lines.any? { |l| l.include?('name:') }
```

#!


#### Practice 3 - Refactoring string keys to symbols

**Goal:** Refactor a string-keyed hash to use symbols.

#> ruby :practice

# TODO: Start from a hash literal with string keys, then build a new
# hash with symbol keys and print both along with a short note about
# readability.

```solution
string_keys = { "title" => "Ruby", "level" => "beginner" }
symbol_keys = { title: "Ruby", level: "beginner" }

puts "string keys: #{string_keys.inspect}"
puts "symbol keys: #{symbol_keys.inspect} (symbols improve readability)"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?(':title') } && lines.any? { |l| l.downcase.include?('symbols') }
```

#!


#### Practice 4 - Non-symbol keys

**Goal:** Experiment with non-symbol hash keys and equality.

#> ruby :practice

# TODO: Create a hash that uses a number and an array as keys, then
# access them and print the results.

```solution
keys = { 1 => "one", [1, 2] => "pair" }

puts "1 maps to: #{keys[1]}"
puts "[1, 2] maps to: #{keys[[1, 2]]}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('[1, 2]') }
```

#!

