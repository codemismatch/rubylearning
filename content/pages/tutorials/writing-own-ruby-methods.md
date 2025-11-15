---
layout: tutorial
title: "Chapter 12 &ndash; Writing Your Own Ruby Methods"
permalink: /tutorials/writing-own-ruby-methods/
difficulty: beginner
summary: Define reusable Ruby methods, add default and variable arguments, use interpolation, and alias older implementations.
previous_tutorial:
  title: "Chapter 11: More on Ruby Methods"
  url: /tutorials/more-on-ruby-methods/
next_tutorial:
  title: "Chapter 13: Ruby `ri` Tool"
  url: /tutorials/ruby-ri-tool/
related_tutorials:
  - title: "Methods & blocks"
    url: /tutorials/methods-and-blocks/
  - title: "Ruby Names"
    url: /tutorials/ruby-names/
---

> Adapted from Satish Talim's "Writing Own Ruby Methods" lesson.

Defining a method is as simple as wrapping logic between `def` and `end`. The last evaluated expression becomes the return value, so you rarely need an explicit `return`.

### Basic method shapes

<pre class="language-ruby"><code class="language-ruby">
# p008mymethods.rb
# Methods that act as queries often end with ?
# Bang methods (!) signal a dangerous or mutating variant

def hello
  "Hello"
end

def hello1(name)
  "Hello #{name}"
end

def hello2 name # parentheses optional
  "Hello #{name}"
end

puts hello
puts hello1("Satish")
puts hello2 "Talim"
</code></pre>

### Default arguments and interpolation

Ruby lets you set default values so callers can omit arguments:

<pre class="language-ruby"><code class="language-ruby">
# p009mymethods1.rb
def mtd(arg1="Dibya", arg2="Shashank", arg3="Shashank")
  "#{arg1}, #{arg2}, #{arg3}."
end

puts mtd
puts mtd("Ruby")
</code></pre>

Interpolation (`#{ ... }`) evaluates the expression and inserts the result into the surrounding string:

<pre class="language-ruby"><code class="language-ruby">
puts &quot;100 * 5 = #{100 * 5}&quot;  # =&gt; 100 * 5 = 500
</code></pre>

Ruby still lacks a way to skip the first argument and only override later ones, so order matters.

### Aliasing methods

Use `alias new_name old_name` to keep the original implementation before redefining it:

<pre class="language-ruby"><code class="language-ruby">
# p010aliasmtd.rb
def oldmtd
  "old method"
end

alias newmtd oldmtd

def oldmtd
  "old improved method"
end

puts oldmtd   # => "old improved method"
puts newmtd   # => "old method"
</code></pre>

Aliases reference a copy of the original method body, so the new name keeps the old behavior even after redefinition.

### Variable arguments (`*args`)

The splat operator collects any number of arguments into an array:

<pre class="language-ruby"><code class="language-ruby">
# p011vararg.rb
def foo(*values)
  values.inspect
end

puts foo("hello", "world")  # ["hello", "world"]
puts foo                     # []
</code></pre>

You can mix splats with required parameters--Ruby pushes arguments left-to-right--so defaults can reference earlier values:

<pre class="language-ruby"><code class="language-ruby">
# p012mtdstack.rb
def mtd(a = 99, b = a + 1)
  [a, b]
end

puts mtd.inspect  # [99, 100]
</code></pre>

### Mutating arguments

Choose whether your methods mutate the objects you receive:

<pre class="language-ruby"><code class="language-ruby">
def downer(str)
  str.downcase
end

name = &quot;HELLO&quot;
downer(name)
puts name  # HELLO (original unchanged)

def downer!(str)
  str.downcase!
end

downer!(name)
puts name  # hello (mutated)
</code></pre>

Following Ruby conventions, the bang version (`downer!`) makes the destructive behavior explicit.

### Practice checklist

- [ ] Create a method that greets users with optional arguments for first and last name; confirm defaults kick in when omitted.
- [ ] Alias a helper method, redefine the original, and ensure both behaviors remain available.
- [ ] Write a `log(*messages)` method that joins an arbitrary number of arguments and prints them.
- [ ] Experiment with pure vs bang-style methods to see how mutating arguments affects callers.

Next: move into Flow Control & Collections to loop over data with the methods you've authored.
