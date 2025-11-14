---
layout: tutorial
title: "Chapter 21 &ndash; Ruby Random Numbers"
permalink: /tutorials/ruby-random-numbers/
difficulty: beginner
summary: Generate pseudo-random floats or integers with `rand`, build fun word mashups, and understand the bounds Ruby applies to each call.
previous_tutorial:
  title: "Chapter 20: Ruby Hashes"
  url: /tutorials/ruby-hashes/
next_tutorial:
  title: "Chapter 22: Read/Write Text Files"
  url: /tutorials/read-write-files/
related_tutorials:
  - title: "Simple Constructs"
    url: /tutorials/simple-constructs/
  - title: "Flow control & collections"
    url: /tutorials/flow-control-collections/
---

> Adapted from Satish Talim’s “Random Numbers” chapter.

Ruby ships with a pseudo-random number generator exposed via `rand`. Use it for quick simulations, toy programs, or any scenario where cryptographic strength isn’t required.

### Basic `rand` usage

- `rand` with no arguments returns a float between `0.0` (inclusive) and `1.0` (exclusive).
- `rand(n)` with an integer argument returns an integer between `0` (inclusive) and `n` (exclusive).

<pre class="language-ruby"><code class="language-ruby">
rand          #=&gt; 0.731245...
rand(5)       #=&gt; 0, 1, 2, 3, or 4
rand(1.5)     # Ruby converts the argument to an integer, so this behaves like rand(1)
</code></pre>

### Example: buzzword generator

<pre class="language-ruby"><code class="language-ruby">
# p026phrase.rb
word_list_one = %w[24/7 multi-Tier 30,000-foot B-to-B win-win front-end web-based pervasive smart six-sigma critical-path dynamic]
word_list_two = %w[empowered sticky value-added oriented centric distributed clustered branded outside-the-box positioned networked focused leveraged aligned targeted shared cooperative accelerated]
word_list_three = %w[process tipping-point solution architecture core\ competency strategy mindshare portal space vision paradigm mission]

rand1 = rand(word_list_one.length)
rand2 = rand(word_list_two.length)
rand3 = rand(word_list_three.length)

phrase = "#{word_list_one[rand1]} #{word_list_two[rand2]} #{word_list_three[rand3]}"
puts phrase
</code></pre>

Each call to `rand(list.length)` picks a valid index, so the script prints a different buzzword combo each run.

### Practice checklist

- [ ] Print ten floats from `rand` and confirm they’re always between 0.0 and 1.0.
- [ ] Roll a virtual die by calling `rand(6) + 1`.
- [ ] Use `rand(range_size)` to select random elements from user-provided arrays.
- [ ] Seed the RNG (`srand(1234)`) and observe how the sequence repeats for reproducible tests.

Next: head back to Flow Control & Collections, where you’ll combine conditionals, loops, and the data structures you’ve learned so far.
