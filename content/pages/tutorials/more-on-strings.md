---
layout: tutorial
title: "Chapter 14 &ndash; More on Strings"
permalink: /tutorials/more-on-strings/
difficulty: beginner
summary: Explore Ruby's rich String toolkit--transformations, comparisons, `%w` literals, and Unicode encodings.
previous_tutorial:
  title: "Chapter 13: Ruby `ri` Tool"
  url: /tutorials/ruby-ri-tool/
next_tutorial:
  title: "Chapter 15: Simple Constructs"
  url: /tutorials/simple-constructs/
related_tutorials:
  - title: "Fun with Strings"
    url: /tutorials/fun-with-strings/
  - title: "Variables & Assignment"
    url: /tutorials/variables-and-assignment/
---

> Adapted from Satish Talim's "More on Strings" lesson, with modern Ruby notes.

Ruby's `String` class packs dozens of helpers. You don't need to memorize them all--`ri String` is available--but a few core families show up constantly.

### Transformation methods

- `reverse`: returns a reversed copy.
- `length`: counts characters (including spaces).
- `upcase`, `downcase`, `swapcase`, `capitalize`: change character case.
- `slice`: extracts substrings.

Each of the case-changing methods has a bang variant (`upcase!`, `downcase!`, etc.) that mutates the receiver to save allocations:

<pre class="language-ruby"><code class="language-ruby">
name = &quot;Ruby&quot;
name.upcase    #=&gt; &quot;RUBY&quot;  (original unchanged)
name.upcase!   #=&gt; &quot;RUBY&quot;  (original modified)
</code></pre>

### Single vs double quotes

Single-quoted literals do minimal processing: only `\'` and `\\` are special, so `'a\b'` equals `'a\\b'`.

Double-quoted literals handle:

1. **Escape sequences** (e.g., `\n`, `\t`).
2. **Interpolation**. The pattern `#{ expression }` evaluates the expression and inserts the result:

<pre class="language-ruby"><code class="language-ruby">
# p013expint.rb
def say_goodnight(name)
  "Good night, #{name}"
end

puts say_goodnight("Satish")
</code></pre>

Each literal creates a new `String` object, so store reused values in constants when it matters.

### String equality

Ruby offers multiple equality checks:

- `==` and `eql?` compare content.
- `equal?` checks object identity.

<pre class="language-ruby"><code class="language-ruby">
# p013strcmp.rb
s1 = "Jonathan"
s2 = "Jonathan"
s3 = s1

puts s1 == s2          # true
puts s1.eql?(s2)       # true
puts s1.equal?(s2)     # false (different objects)
puts s1.equal?(s3)     # true  (same object)
</code></pre>

### `%w` word arrays

Skip repetitive quotes and commas when you just need an array of bare words:

<pre class="language-ruby"><code class="language-ruby">
names = %w[ann richard william susan pat]
puts names[0] # ann
puts names[3] # susan
</code></pre>

Ruby ignores extra whitespace inside `%w{ ... }`.

### Character sets and encodings

- A **character set** maps symbols to numeric code points (e.g., Unicode's U+0048 for "H").
- An **encoding** describes how to store those code points (UTF-8 uses 1-4 bytes).
- Ruby tracks encoding metadata on each string via `Encoding`.

List supported encodings:

<pre class="language-ruby"><code class="language-ruby">
Encoding.list.each { |enc| puts enc.name }
</code></pre>

Default source encoding is US-ASCII unless you override it with a magic comment:

<pre class="language-ruby"><code class="language-ruby">
# coding: utf-8
# encoding: utf-8  # equivalent
</code></pre>

Ruby also honors UTF-8 byte order marks (`\xEF\xBB\xBF`).

### String introspection

Use `String.methods.sort` to see class-level helpers, and `String.instance_methods.sort` for instance methods. Pass `false` to exclude ancestors:

<pre class="language-ruby"><code class="language-ruby">
String.instance_methods(false).sort.take(10)
</code></pre>

### Practice checklist

- [ ] Recreate `say_goodnight` using single quotes and observe how interpolation stops working.
- [ ] Write a script that compares two user inputs with `==`, `eql?`, and `equal?`.
- [ ] Build a `%w` array of Ruby core types and iterate over it.
- [ ] Print each string's encoding (e.g., `"Ola".encoding`) and experiment with `#encode` to convert between UTF-8 and another encoding.

Next: put these string skills to work while branching and looping through Flow Control & Collections.
