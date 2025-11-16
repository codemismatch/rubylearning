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

#### Practice 1 - Shared references and mutation

<p><strong>Goal:</strong> Show how two arrays referencing the same object mutate together after `<<`.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/mutable-and-immutable-objects"
     data-practice-index="0"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('before:') } && lines.any? { |l| l.downcase.include?('after:') }"><code class="language-ruby">
# TODO: Create one array, assign it to two variables, push a value via
# one variable, and print both before and after to show they point to
# the same object.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/mutable-and-immutable-objects"
     data-practice-index="0"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/mutable-and-immutable-objects:0">
nums = [1, 2]
alias_ref = nums

puts "before: nums=#{nums.inspect}, alias_ref=#{alias_ref.inspect}"

nums << 3

puts "after:  nums=#{nums.inspect}, alias_ref=#{alias_ref.inspect}"
</script>

#### Practice 2 - Freezing and FrozenError

<p><strong>Goal:</strong> Freeze a string and rescue the `FrozenError` when appending to it.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/mutable-and-immutable-objects"
     data-practice-index="1"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('frozenerror') }"><code class="language-ruby">
# TODO: Freeze a string and attempt to append to it, rescuing the
# FrozenError and printing a short message.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/mutable-and-immutable-objects"
     data-practice-index="1"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/mutable-and-immutable-objects:1">
greeting = "hello".freeze

begin
  greeting << " world"
rescue FrozenError => e
  puts "Caught FrozenError: #{e.message}"
end
</script>

#### Practice 3 - Immutable symbol keys

<p><strong>Goal:</strong> Explain why symbol keys in hashes don't need cloning.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/mutable-and-immutable-objects"
     data-practice-index="2"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?(':name') } && lines.any? { |l| l.downcase.include?('immutable') }"><code class="language-ruby">
# TODO: Create a hash with symbol keys, access them, and print a
# sentence noting that symbols are immutable and reused, so the keys
# don't need cloning.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/mutable-and-immutable-objects"
     data-practice-index="2"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/mutable-and-immutable-objects:2">
person = { name: "Rubyist", city: "Pune" }

puts "Keys: #{person.keys.inspect}"
puts "name: #{person[:name]}"
puts "Symbols are immutable and reused, so hash keys like :name don't need cloning."
</script>

#### Practice 4 - Duplicating before modifying

<p><strong>Goal:</strong> Use `dup` to copy a mutable object before modifying it.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/mutable-and-immutable-objects"
     data-practice-index="3"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('original:') } && lines.any? { |l| l.downcase.include?('copy:') }"><code class="language-ruby">
# TODO: Start with a single array or string, create a dup, mutate the
# copy, and print both original and copy to show only the copy changed.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/mutable-and-immutable-objects"
     data-practice-index="3"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/mutable-and-immutable-objects:3">
original = [1, 2, 3]
copy = original.dup

copy << 4

puts "original: #{original.inspect}"
puts "copy:     #{copy.inspect}"
</script>
