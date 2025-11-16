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

#### Practice 1 - Greeting with optional arguments

<p><strong>Goal:</strong> Create a method that greets users with optional first and last name arguments.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/writing-own-ruby-methods"
     data-practice-index="0"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('hello') } && lines.any? { |l| l.downcase.include?('guest') }"><code class="language-ruby">
# TODO: Define greet(first = \"Guest\", last = nil) and print at least
# one greeting that uses defaults and one that passes both names.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/writing-own-ruby-methods"
     data-practice-index="0"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/writing-own-ruby-methods:0">
puts "def greet(first = 'Guest', last = nil)"
puts "  name = [first, last].compact.join(' ')"
puts "  puts \"Hello, #{name}\""
puts "end"
</script>

#### Practice 2 - Aliasing and redefining methods

<p><strong>Goal:</strong> Alias a helper method, redefine the original, and ensure both behaviours remain available.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/writing-own-ruby-methods"
     data-practice-index="1"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('alias') }"><code class="language-ruby">
# TODO: Sketch a method, alias it, then redefine the original while
# the alias retains the earlier behaviour.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/writing-own-ruby-methods"
     data-practice-index="1"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/writing-own-ruby-methods:1">
puts "def hello; 'hi'; end"
puts "alias old_hello hello"
puts "def hello; 'hello'; end"
</script>

#### Practice 3 - Variadic log(*messages)

<p><strong>Goal:</strong> Write a `log(*messages)` method that joins an arbitrary number of arguments and prints them.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/writing-own-ruby-methods"
     data-practice-index="2"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('log:') }"><code class="language-ruby">
# TODO: Define log(*messages) to join its arguments with spaces and
# print a single line.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/writing-own-ruby-methods"
     data-practice-index="2"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/writing-own-ruby-methods:2">
puts "def log(*messages)"
puts "  puts \"log: #{messages.join(' ')}\""
puts "end"
</script>

#### Practice 4 - Pure vs bang-style methods

<p><strong>Goal:</strong> Experiment with pure vs bang-style methods to see how mutating arguments affects callers.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/writing-own-ruby-methods"
     data-practice-index="3"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('pure') } && lines.any? { |l| l.include?('bang') }"><code class="language-ruby">
# TODO: Print a small example of a pure helper that returns a new
# value and a bang-style helper that mutates an argument.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/writing-own-ruby-methods"
     data-practice-index="3"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/writing-own-ruby-methods:3">
puts "def pure_upcase(str)"
puts "  str.upcase"
puts "end"
puts "def bang_upcase!(str)"
puts "  str.upcase!"
puts "end"
</script>
