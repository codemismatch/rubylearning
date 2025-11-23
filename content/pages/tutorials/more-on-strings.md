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

```ruby-exec
name = "Ruby"
name.upcase    #=> "RUBY"  (original unchanged)
name.upcase!   #=> "RUBY"  (original modified)
```

### Single vs double quotes

Single-quoted literals do minimal processing: only `\'` and `\\` are special, so `'a\b'` equals `'a\\b'`.

Double-quoted literals handle:

1. **Escape sequences** (e.g., `\n`, `\t`).
2. **Interpolation**. The pattern `#{ expression }` evaluates the expression and inserts the result:

```ruby-exec
# p013expint.rb
def say_goodnight(name)
  "Good night, #{name}"
end

puts say_goodnight("Satish")
```

Each literal creates a new `String` object, so store reused values in constants when it matters.

### String equality

Ruby offers multiple equality checks:

- `==` and `eql?` compare content.
- `equal?` checks object identity.

```ruby-exec
# p013strcmp.rb
s1 = "Jonathan"
s2 = "Jonathan"
s3 = s1

puts s1 == s2          # true
puts s1.eql?(s2)       # true
puts s1.equal?(s2)     # false (different objects)
puts s1.equal?(s3)     # true  (same object)
```

### `%w` word arrays

Skip repetitive quotes and commas when you just need an array of bare words:

```ruby-exec
names = %w[ann richard william susan pat]
puts names[0] # ann
puts names[3] # susan
```

Ruby ignores extra whitespace inside `%w{ ... }`.

### Character sets and encodings

- A **character set** maps symbols to numeric code points (e.g., Unicode's U+0048 for "H").
- An **encoding** describes how to store those code points (UTF-8 uses 1-4 bytes).
- Ruby tracks encoding metadata on each string via `Encoding`.

List supported encodings:

```ruby-exec
Encoding.list.each { |enc| puts enc.name }
```

Default source encoding is US-ASCII unless you override it with a magic comment:

```ruby-exec
# coding: utf-8
# encoding: utf-8  # equivalent
```

Ruby also honors UTF-8 byte order marks (`\xEF\xBB\xBF`).

### String introspection

Use `String.methods.sort` to see class-level helpers, and `String.instance_methods.sort` for instance methods. Pass `false` to exclude ancestors:

```ruby-exec
String.instance_methods(false).sort.take(10)
```

### Practice checklist

- [ ] Recreate `say_goodnight` using single quotes and observe how interpolation stops working.
- [ ] Write a script that compares two user inputs with `==`, `eql?`, and `equal?`.
- [ ] Build a `%w` array of Ruby core types and iterate over it.
- [ ] Print each string's encoding (e.g., `"Ola".encoding`) and experiment with `#encode` to convert between UTF-8 and another encoding.

Next: put these string skills to work while branching and looping through Flow Control & Collections.

#### Practice 1 - Interpolation vs single quotes

**Goal:** Recreate `say_goodnight` using single quotes and observe how interpolation behaves.</p>

#> ruby :practice

# TODO: Implement say_goodnight twice: once with double quotes that
# interpolate a name, and once with single quotes that leave #{name}
# unchanged. Print both results.

```solution
def say_goodnight_double(name)
  "Good night, #{name}"
end

def say_goodnight_single(name)
  'Good night, #{name}'
end

puts say_goodnight_double("Rubyist")
puts say_goodnight_single("Rubyist")
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?(\
```

#!


#### Practice 2 - Comparing user inputs

**Goal:** Compare two strings with `==`, `eql?`, and `equal?`.

#> ruby :practice

# TODO: Read or define two strings, compare them with ==, eql?,
# and equal?, and print a labelled line for each comparison.

```solution
s1 = "Jonathan"
s2 = "Jonathan"
s3 = s1

puts "== : #{s1 == s2}"
puts "eql?: #{s1.eql?(s2)}"
puts "equal? (s1,s2): #{s1.equal?(s2)}"
puts "equal? (s1,s3): #{s1.equal?(s3)}"
```

```test
out = output.string; lines = out.lines.map(&:strip); %w[== eql? equal?].all? { |m| lines.any? { |l| l.include?(m) } }
```

#!


#### Practice 3 - Building a %w array

**Goal:** Build a `%w` array of Ruby core types and iterate over it.

#> ruby :practice

# TODO: Use %w to construct an array of Ruby core type names, then
# iterate and print each element with a short label.

```solution
types = %w[String Array Hash Symbol]

types.each do |name|
  puts "Core type: #{name}"
end
```

```test
out = output.string; lines = out.lines.map(&:strip); %w[String Array Hash Symbol].all? { |word| lines.any? { |l| l.include?(word) } }
```

#!


#### Practice 4 - Working with encodings

**Goal:** Print each string's encoding and experiment with `#encode`.

#> ruby :practice

# TODO: Create a couple of strings, print their encoding, and call
# encode on at least one of them to convert it to a different encoding.

```solution
hello = "Olá"

puts "Original encoding: #{hello.encoding}"
converted = hello.encode("UTF-8")
puts "Converted encoding: #{converted.encoding}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('encoding') }
```

#!

