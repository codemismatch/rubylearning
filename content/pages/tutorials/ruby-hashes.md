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

> Adapted from Satish Talim’s Ruby Hashes lesson.

Hashes (aka associative arrays, maps, dictionaries) pair any object as a **key** to any object as a **value**. Unlike arrays, which use integer indexes, hashes can use strings, symbols, regexes, numbers—anything that implements `hash` and `eql?`.

### Hash literals and access

<pre class="language-ruby"><code class="language-ruby">
# p040myhash.rb
h = { "dog" => "canine", "cat" => "feline", "donkey" => "asinine", 12 => "dodecine" }

puts h.length   # 4
puts h["dog"]   # canine
puts h[12]      # dodecine
puts h          # prints the whole hash
</code></pre>

- Missing keys return `nil` unless you provide a default (`Hash.new("Unknown")`).
- Hashes are unordered prior to Ruby 1.9; newer Rubies preserve insertion order.

### Symbols as hash keys

Symbols make efficient, readable keys:

<pre class="language-ruby"><code class="language-ruby">
# p041symbolhash.rb
person = {}
person[:nickname] = "IndianGuru"
person[:language] = "Marathi"
person[:lastname] = "Talim"

puts person[:lastname] # Talim
</code></pre>

Modern Ruby supports the JSON-style literal when keys are symbols:

<pre class="language-ruby"><code class="language-ruby">
# p0411symbolhash.rb
person = { :nickname => "IndianGuru", :language => "Marathi", :lastname => "Talim" }

# p0412symbolhash.rb
person = { nickname: "IndianGuru", language: "Marathi", lastname: "Talim" }
</code></pre>

Both yield `{ :nickname=>"IndianGuru", :language=>"Marathi", :lastname=>"Talim" }`. The short `{ key: value }` syntax works only for symbol keys; use the hashrocket (`=>`) for strings, numbers, or other objects (`{ 1 => "one" }`).

### Defaults and lookup

<pre class="language-ruby"><code class="language-ruby">
counts = Hash.new(0)
counts[:apples] += 1
puts counts[:missing]  # 0 instead of nil
</code></pre>

This pattern is handy for tallies and grouping. For nested hashes, consider `Hash.new { |h, k| h[k] = {} }`.

### Practice checklist

- [ ] Recreate `p040myhash.rb`, then set a default value to see how missing keys behave.
- [ ] Build a hash using the JSON-style literal and confirm it matches the hashrocket version.
- [ ] Refactor a string-keyed hash to use symbols and notice the improved readability.
- [ ] Experiment with non-symbol keys (numbers, arrays) to see how Ruby handles equality.

Next: with symbols and hashes under your belt, continue into Flow Control & Collections where these structures help drive iterators and data transformations.
