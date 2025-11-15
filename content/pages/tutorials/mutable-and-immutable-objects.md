---
layout: tutorial
title: "Chapter 38 &ndash; Mutable vs Immutable Objects"
permalink: /tutorials/mutable-and-immutable-objects/
difficulty: beginner
summary: Know which Ruby objects change in place (strings, arrays) and which do not (numbers, symbols), and how `freeze` locks state.
previous_tutorial:
  title: "Chapter 37: Ruby Syntactic Sugar"
  url: /tutorials/ruby-syntactic-sugar/
next_tutorial:
  title: "Chapter 39: Object Serialization (Marshal)"
  url: /tutorials/object-serialization/
related_tutorials:
  - title: "Ruby Symbols"
    url: /tutorials/ruby-symbols/
  - title: "Ruby Open Classes"
    url: /tutorials/ruby-open-classes/
---

> Adapted from Satish Talim's "Mutable and Immutable Objects" lesson.

Ruby stores some objects as mutable containers (strings, arrays, hashes) and others as immutable values (numbers, symbols). Understanding the difference prevents surprises when multiple variables reference the same object.

### Mutable example: strings

<pre class="language-ruby"><code class="language-ruby">
name = "Ruby"
alias = name

name.upcase!
puts alias  #=> "RUBY"
</code></pre>

`alias` changed because both variables point to the same mutable string object.

### Immutable example: numbers

<pre class="language-ruby"><code class="language-ruby">
count = 10
other = count

count += 5
puts other  #=> 10
</code></pre>

Numeric literals are immutable immediate values; arithmetic always returns a new object.

### Symbols are immutable

Symbols are allocated once and never modified:

<pre class="language-ruby"><code class="language-ruby">
status = :ok
# :ok is frozen automatically; no bang methods mutate it
</code></pre>

### Freezing objects

Call `freeze` to prevent further modification:

<pre class="language-ruby"><code class="language-ruby">
config = { retries: 3 }.freeze
config[:timeout] = 10  # raises FrozenError
</code></pre>

Frozen strings are common when `# frozen_string_literal: true` appears at the top of a file.

### Practice checklist

- [ ] Demonstrate how two arrays referencing the same object both mutate after `<<`.
- [ ] Freeze a string and rescue the `FrozenError` raised when attempting to append to it.
- [ ] Explain why symbol keys in hashes don't need cloning--they're immutable.
- [ ] Use `dup` to copy a mutable object before modifying it.

Next: continue into Flow Control & Collections, now mindful of which objects mutate in place.
