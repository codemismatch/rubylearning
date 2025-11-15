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
