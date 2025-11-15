---
layout: tutorial
title: "Chapter 15 &ndash; Simple Constructs"
permalink: /tutorials/simple-constructs/
difficulty: beginner
summary: Get comfortable with Ruby's core control-flow tools--`if`, `elsif`, `unless`, loops, ternaries, `case`, and the truthiness rules around `nil`.
previous_tutorial:
  title: "Chapter 14: More on Strings"
  url: /tutorials/more-on-strings/
next_tutorial:
  title: "Chapter 16: Ruby Blocks"
  url: /tutorials/ruby-blocks/
related_tutorials:
  - title: "Flow control & collections"
    url: /tutorials/flow-control-collections/
  - title: "Ruby Names"
    url: /tutorials/ruby-names/
---

> Adapted from Satish Talim's "Simple Constructs" lesson.

Ruby keeps branching syntax lightweight. Parentheses on `if`/`while` are optional, and indentation follows the semantic blocks (`if ... end`).

### `if`, nested blocks, and `elsif`

<pre class="language-ruby"><code class="language-ruby">
# p014constructs.rb
var = 5

if var > 4
  puts "Variable is greater than 4"
  if var == 5
    puts "Nested if else possible"
  else
    puts "Too cool"
  end
else
  puts "Variable is not greater than 4"
end
</code></pre>

`elsif` cleans up stacked `if`/`else` chains:

<pre class="language-ruby"><code class="language-ruby">
# p015elsifex.rb
puts "Hello, what's your name?"
STDOUT.flush
name = gets.chomp

if name == "Satish"
  puts "What a nice name!!"
elsif name == "Sunil"
  puts "Another nice name!"
end

# Logical OR combines checks on one line
puts "Hello again..."
if name == "Satish" || name == "Sunil"
  puts "Still a great name!"
end
</code></pre>

Truthiness recap: only `false` and `nil` evaluate as false. `0` and empty strings are truthy.

### `unless` and loops

`unless` is the inverse of `if`:

<pre class="language-ruby"><code class="language-ruby">
unless ARGV.length == 2
  puts &quot;Usage: program.rb 23 45&quot;
  exit
end
</code></pre>

`while` handles simple loops:

<pre class="language-ruby"><code class="language-ruby">
var = 0
while var &lt; 10
  puts var
  var += 1
end
</code></pre>

### Ternary operator (`?:`)

Use the ternary operator for compact conditional expressions:

<pre class="language-ruby"><code class="language-ruby">
age = 15
puts (13...19).include?(age) ? &quot;teenager&quot; : &quot;not a teenager&quot;

person = (13...19).include?(23) ? &quot;teenager&quot; : &quot;not a teenager&quot;
</code></pre>

### Statement modifiers

When the body is a single expression, place the condition after the statement:

<pre class="language-ruby"><code class="language-ruby">
puts &quot;Enrollments will now stop&quot; if participants &gt; 2500
warn &quot;Missing args&quot; unless ARGV.any?
</code></pre>

### `case` expressions

`case` is Ruby's flexible multi-branch construct and always returns the last evaluated expression:

<pre class="language-ruby"><code class="language-ruby">
year = 2000
leap = case
when year % 400 == 0 then true
when year % 100 == 0 then false
else year % 4 == 0
end

puts leap #=&gt; true
</code></pre>

You can also supply a target (`case value`), but the conditionless style above keeps things flexible.

### `nil` vs `false`

Both values are falsy, but they are different objects with different classes and IDs:

<pre class="language-ruby"><code class="language-ruby">
puts nil.class    # NilClass
puts false.class  # FalseClass
puts nil.object_id    # 4
puts false.object_id  # 0
</code></pre>

Remember: `nil` is a real object (`NilClass`) and responds to methods just like any other object.

### Practice checklist

- [ ] Rewrite an `if`/`else` tree using `elsif` and then with logical operators to reduce nesting.
- [ ] Use `unless` to validate command-line arguments, then swap it with `if` to see which reads better.
- [ ] Convert a small `if/else` assignment into a ternary expression and back.
- [ ] Build a `case` expression that categorizes numeric ranges (e.g., fizz/buzz or temperature bands).

Next: dive deeper into Flow Control & Collections to combine these constructs with loops, arrays, and hashes.
