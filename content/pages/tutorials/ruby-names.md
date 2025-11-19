---
layout: tutorial
title: "Chapter 10 &ndash; Ruby Names"
permalink: /tutorials/ruby-names/
difficulty: beginner
summary: Learn how Ruby names distinguish locals, instances, classes, globals, and constants, plus see how Ruby treats objects and numeric types under the hood.
previous_tutorial:
  title: "Chapter 9: Getting Input"
  url: /tutorials/getting-input/
next_tutorial:
  title: "Chapter 11: More on Ruby Methods"
  url: /tutorials/more-on-ruby-methods/
related_tutorials:
  - title: "Scope"
    url: /tutorials/scope/
  - title: "Variables & Assignment"
    url: /tutorials/variables-and-assignment/
---

> Adapted from Satish Talim's "Ruby Names" lesson, with refreshed examples for the modern stack.

Ruby names refer to the labels you use for variables, methods, classes, modules, and constants. The first character signals Ruby's intent: lowercase for locals, `@` for instances, `@@` for class-level state, `$` for globals, and uppercase for constants.

### Variable families at a glance

<pre class="language-ruby" data-executable="true"><code class="language-ruby">
sunil      = &quot;local&quot;      # lowercase or _ prefix
@count     = 1            # instance variable belongs to self
@@registry = {}           # class variable shared across instances
$mode      = &quot;demo&quot;       # global variable (avoid unless necessary)
</code></pre>

- **Local variables** start with a lowercase letter or underscore (`_transactions`). They spring into existence the first time you assign to them.
- **Instance variables** begin with `@` and always belong to the current object referenced by `self`.
- **Class variables** begin with `@@`. They are shared by a class and its subclasses; use sparingly because they are easy to misuse.
- **Global variables** start with `$` and are visible everywhere. Ruby also predefines many globals such as `$0` (script name) and `$:` (load path).

### Constants, classes, and modules

Constants start with a capital letter:

<pre class="language-ruby" data-executable="true"><code class="language-ruby">
module MyMath
  PI = 3.1416
end

class MyPune
end
</code></pre>

Ruby allows you to reassign constants but prints a warning. Treat them as immutable configuration or types such as class/module names.

### Method naming conventions

- Method names should start with a lowercase letter or `_`.
- Allowed suffixes: `?` for predicate methods (`empty?`), `!` for "dangerous" variants (`save!`), and `=` for attribute writers (`name=`).
- Use snake_case for multi-word names and ALL_CAPS for constant-style identifiers.

### Ruby is dynamically typed

Variables reference objects, and you can bind different object types to the same variable as needed:

<pre class="language-ruby" data-executable="true"><code class="language-ruby">
# p007dt.rb
# Ruby is dynamic
x = 7         # Integer
x = "house"   # String
x = 7.5       # Float

'I love Ruby'.length
</code></pre>

Ruby automatically manages references and garbage collection, so there is no separate "primitive" vs "object" concept--everything is an object.

### Numeric classes and huge values

Ruby handles large numbers transparently by switching between `Integer` (formerly `Fixnum`/`Bignum`) under the hood. Floats live under `Float`, a subclass of `Numeric`, and expose useful constants:

<pre class="language-ruby" data-executable="true"><code class="language-ruby">
puts Float::DIG  # precision in decimal digits
puts Float::MAX  # largest Float for your architecture
</code></pre>

Need to scale dramatically? Ruby keeps going:

<pre class="language-ruby" data-executable="true"><code class="language-ruby">
rice_on_square = 1
64.times do |square|
  puts "On square #{square + 1} are #{rice_on_square} grain(s)"
  rice_on_square *= 2
end
</code></pre>

By the final square you are counting trillions of grains--Ruby handles it seamlessly.

### Inspecting classes and `self`

Because everything is an object, you can always ask Ruby about its class or inspect itself:

<pre class="language-ruby" data-executable="true"><code class="language-ruby">
puts "I am in class = #{self.class}"
puts "I am an object = #{self}"
puts "My private methods include: #{self.private_methods.sort.take(5)}..."
</code></pre>

Blocks enhance readability too:

<pre class="language-ruby" data-executable="true"><code class="language-ruby">
5.times { puts "Mice!" }
"Elephants Like Peanuts".length
</code></pre>

### Practice checklist

- [ ] Declare one variable of each scope type (`local`, `@instance`, `@@class`, `$global`) and log them from inside a class to see which are accessible.
- [ ] Create a module with a constant, then try reassigning it to observe Ruby's warning.
- [ ] Write a script that prints `Float::DIG` and `Float::MAX` plus the class of a huge integer to confirm Ruby's automatic promotion.
- [ ] Reproduce the rice-on-a-chessboard example and experiment with different iteration counts to see how quickly the value grows.

Next: move into Flow Control & Collections to apply these naming rules inside loops and conditionals.

#### Practice 1 - Variable scopes

<p><strong>Goal:</strong> Declare variables of each scope type and log them from inside a class.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-names"
     data-practice-index="0"
     data-test="out = output.string; lines = out.lines.map(&:strip); %w[local @instance @@class $global].all? { |tok| lines.any? { |l| l.include?(tok) } }"><code class="language-ruby">
# TODO: Sketch a snippet that uses a local, @instance, @@class, and
# $global variable and prints which ones are visible from where.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-names"
     data-practice-index="0"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-names:0">
puts "local = 'local'"
puts "@instance = 'instance'"
puts "@@class = 'class'"
puts "$global = 'global'"
</script>

#### Practice 2 - Module constants and warnings

<p><strong>Goal:</strong> Create a module with a constant and try reassigning it.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-names"
     data-practice-index="1"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('MyModule::NAME') } && lines.any? { |l| l.downcase.include?('warning') }"><code class="language-ruby">
# TODO: Print an example that defines and then reassigns a module
# constant, noting Ruby will warn about it.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-names"
     data-practice-index="1"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-names:1">
puts "module MyModule"
puts "  NAME = 'original'"
puts "end"
puts "MyModule::NAME = 'changed' # Ruby warns about already initialized constant"
</script>

#### Practice 3 - Float limits and big integers

<p><strong>Goal:</strong> Print `Float::DIG`, `Float::MAX`, and the class of a huge integer.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-names"
     data-practice-index="2"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('Float::DIG') } && lines.any? { |l| l.downcase.include?('bignum') || l.downcase.include?('integer') }"><code class="language-ruby">
# TODO: Print Float::DIG, Float::MAX, and inspect the class of a very
# large integer literal.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-names"
     data-practice-index="2"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-names:2">
puts "Float::DIG"
puts "Float::MAX"
puts "(10**50).class # Integer/Bignum depending on Ruby version"
</script>

#### Practice 4 - Rice-on-a-chessboard growth

<p><strong>Goal:</strong> Reproduce the rice-on-a-chessboard example and experiment with growth.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-names"
     data-practice-index="3"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('square') } && lines.any? { |l| l.downcase.include?('total') }"><code class="language-ruby">
# TODO: Print a small script that doubles grains each square and
# prints the total at the end.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-names"
     data-practice-index="3"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-names:3">
puts "total = 0"
puts "grains = 1"
puts "64.times do |square|"
puts "  total += grains"
puts "  grains *= 2"
puts "end"
puts "puts \"total grains: \#{total}\""
</script>
