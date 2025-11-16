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

#### Practice 1 - Interpolation vs single quotes

<p><strong>Goal:</strong> Recreate `say_goodnight` using single quotes and observe how interpolation behaves.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/more-on-strings"
     data-practice-index="0"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?(\"Good night, \") } && lines.any? { |l| l.include?('#{name}') }"><code class="language-ruby">
# TODO: Implement say_goodnight twice: once with double quotes that
# interpolate a name, and once with single quotes that leave #{name}
# unchanged. Print both results.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/more-on-strings"
     data-practice-index="0"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/more-on-strings:0">
def say_goodnight_double(name)
  "Good night, #{name}"
end

def say_goodnight_single(name)
  'Good night, #{name}'
end

puts say_goodnight_double("Rubyist")
puts say_goodnight_single("Rubyist")
</script>

#### Practice 2 - Comparing user inputs

<p><strong>Goal:</strong> Compare two strings with `==`, `eql?`, and `equal?`.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/more-on-strings"
     data-practice-index="1"
     data-test="out = output.string; lines = out.lines.map(&:strip); %w[== eql? equal?].all? { |m| lines.any? { |l| l.include?(m) } }"><code class="language-ruby">
# TODO: Read or define two strings, compare them with ==, eql?,
# and equal?, and print a labelled line for each comparison.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/more-on-strings"
     data-practice-index="1"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/more-on-strings:1">
s1 = "Jonathan"
s2 = "Jonathan"
s3 = s1

puts "== : #{s1 == s2}"
puts "eql?: #{s1.eql?(s2)}"
puts "equal? (s1,s2): #{s1.equal?(s2)}"
puts "equal? (s1,s3): #{s1.equal?(s3)}"
</script>

#### Practice 3 - Building a %w array

<p><strong>Goal:</strong> Build a `%w` array of Ruby core types and iterate over it.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/more-on-strings"
     data-practice-index="2"
     data-test="out = output.string; lines = out.lines.map(&:strip); %w[String Array Hash Symbol].all? { |word| lines.any? { |l| l.include?(word) } }"><code class="language-ruby">
# TODO: Use %w to construct an array of Ruby core type names, then
# iterate and print each element with a short label.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/more-on-strings"
     data-practice-index="2"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/more-on-strings:2">
types = %w[String Array Hash Symbol]

types.each do |name|
  puts "Core type: #{name}"
end
</script>

#### Practice 4 - Working with encodings

<p><strong>Goal:</strong> Print each string's encoding and experiment with `#encode`.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/more-on-strings"
     data-practice-index="3"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('encoding') }"><code class="language-ruby">
# TODO: Create a couple of strings, print their encoding, and call
# encode on at least one of them to convert it to a different encoding.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/more-on-strings"
     data-practice-index="3"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/more-on-strings:3">
hello = "Olá"

puts "Original encoding: #{hello.encoding}"
converted = hello.encode("UTF-8")
puts "Converted encoding: #{converted.encoding}"
</script>
