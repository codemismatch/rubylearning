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

<pre class="language-ruby"><code class="language-ruby">
class Person
  attr_accessor :name, :email
end
</code></pre>

This expands to getter/setter methods--no need to write them manually.

### Operator methods

`a + b` is shorthand for `a.+(b)`. Many operators are method calls, so you can override them when needed (`<<`, `[]`, etc.).

### Inline modifiers

<pre class="language-ruby"><code class="language-ruby">
puts &quot;Hello&quot; if logged_in?
retry_count += 1 while retry_needed?
</code></pre>

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

<p><strong>Goal:</strong> Replace manual getter/setter methods with `attr_accessor`.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-syntactic-sugar"
     data-practice-index="0"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('attr_accessor') }"><code class="language-ruby">
# TODO: Print a small class definition before/after showing how
# attr_accessor replaces handwritten getter/setter methods.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-syntactic-sugar"
     data-practice-index="0"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-syntactic-sugar:0">
puts "class User"
puts "  attr_accessor :name"
puts "end"
</script>

#### Practice 2 - Using %w for arrays of strings

<p><strong>Goal:</strong> Use `%w` to rewrite an array of strings without repetitive quotes.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-syntactic-sugar"
     data-practice-index="1"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('%w[') }"><code class="language-ruby">
# TODO: Print an array of string literals, then show the equivalent
# using %w.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-syntactic-sugar"
     data-practice-index="1"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-syntactic-sugar:1">
puts 'names = ["ann", "bob", "carla"]'
puts 'names = %w[ann bob carla]'
</script>

#### Practice 3 - Inline if modifier

<p><strong>Goal:</strong> Convert a multi-line `if` to an inline modifier where readability improves.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-syntactic-sugar"
     data-practice-index="2"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('if user.admin?') }"><code class="language-ruby">
# TODO: Print a before/after example where a single-line action with
# an if modifier reads more cleanly than a full if/end block.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-syntactic-sugar"
     data-practice-index="2"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-syntactic-sugar:2">
puts 'notify_admin if user.admin?'
</script>

#### Practice 4 - Implementing << in a custom class

<p><strong>Goal:</strong> Implement `<<` in a custom class to append items.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-syntactic-sugar"
     data-practice-index="3"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('def <<') }"><code class="language-ruby">
# TODO: Print a class that defines << to append values to an internal
# array, returning self for chaining.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-syntactic-sugar"
     data-practice-index="3"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-syntactic-sugar:3">
puts "class Bag"
puts "  def initialize"
puts "    @items = []"
puts "  end"
puts "  def <<(item)"
puts "    @items << item"
puts "    self"
puts "  end"
puts "end"
</script>
