---
layout: tutorial
title: "Chapter 5 &ndash; Numbers in Ruby"
permalink: /tutorials/numbers-in-ruby/
difficulty: beginner
summary: Work with integers, floats, and Ruby's arithmetic operators while learning handy idioms like ||= and modulo rules.
previous_tutorial:
  title: "Chapter 4: Ruby Features"
  url: /tutorials/ruby-features/
next_tutorial:
  title: "Chapter 6: Fun with Strings"
  url: /tutorials/fun-with-strings/
related_tutorials:
  - title: "Flow control & collections"
    url: /tutorials/flow-control-collections/
  - title: "Ruby resources"
    url: /pages/resources/
---

> Adapted from Satish Talim's original RubyLearning notes, refreshed for Typophic.

Ruby treats everything as an object, including numbers. Integers live under `Integer`, floats under `Float`, and both inherit helpers from `Numeric`. Let's explore literal syntax, arithmetic, and boolean operators before we lean on them in later chapters.

### Number literals

- Integers omit decimal points: `0`, `123`, `-99`.
- Floats must include a decimal: `3.14`, `0.5`, `-10.0`.
- Use underscores for readability&mdash;they are ignored by the interpreter: `1_000_000`.

Ruby infers the class from the literal:

<pre class="language-ruby" data-executable="true"><code class="language-ruby">
42.class    #=&gt; Integer
3.14.class  #=&gt; Float
</code></pre>

### Quick arithmetic tour

Here's the modern take on Satish's `p002rubynumbers.rb`. Mix integers and floats to see how Ruby changes the result type.

<pre class="language-ruby" data-executable="true"><code class="language-ruby">
# numbers.rb
=begin
Ruby Numbers
Usual operators:
+ addition
- subtraction
* multiplication
/ division
=end

puts 1 + 2         # 3
puts 2 * 3         # 6
puts 3 / 2         # 1 (integer division)
puts 10 - 11       # -1
puts 1.5 / 2.6     # 0.5769230769230769 (float division)
</code></pre>

When both operands are integers, Ruby performs integer division. Add one float (or call `to_f`) to get a float result.

### Modulo rules you can rely on

Ruby's modulo operator `%` follows the sign of the second operand. That's friendlier than the C/Java approach because you can predict outcomes for negative numbers:

<pre class="language-ruby" data-executable="true"><code class="language-ruby">
puts 5 % 3    # 2
puts -5 % 3   # 1
puts 5 % -3   # -1
puts -5 % -3  # -2
</code></pre>

### Boolean operators: `||` vs `or`

Both operators return the first truthy operand, or the second when the first is `nil`/`false`. Their only difference is precedence.

<pre class="language-ruby" data-executable="true"><code class="language-ruby">
puts nil || 2008   # 2008
puts false || 2008 # 2008
puts &quot;ruby&quot; || 2008 # &quot;ruby&quot;
</code></pre>

- Use `||` inside expressions and assignments because it has higher precedence.
- Use the English keywords (`or`, `and`) when stringing together whole clauses; they read nicely and have lower precedence than assignment.

Rubyists often combine `||` with assignment to set defaults:

<pre class="language-ruby" data-executable="true"><code class="language-ruby">
@token = @token || &quot;default value&quot;
@token ||= &quot;default value&quot; # idiomatic shorthand
</code></pre>

### Short-circuit assignment chains

Low-precedence keywords make it possible to run a series of assignments until one returns a falsey value:

<pre class="language-ruby" data-executable="true"><code class="language-ruby">
def capture(value)
  value
end

if a = capture(true) and
  b = capture(&quot;two&quot;) and
  c = capture(false)
  result = [a, b, c]
end

p result # nil because c is false
</code></pre>

Swap `and` for `&&` in the snippet above and the assignments no longer behave as intended, because `&&` binds tighter than `=`. Use the keyword when you specifically want the assignments to run left-to-right.

### Practice checklist

- [ ] Recreate `numbers.rb` locally and observe how integer vs float division change the output.
- [ ] Experiment with `%` using positive and negative operands to internalize the sign rule.
- [ ] Use `||=` to set default configuration in `first_program.rb`.
- [ ] Replace `&&` with `and` (and vice versa) in a test script to see how precedence affects assignment expressions.

#### Practice 1 - Integer vs float division

<p><strong>Goal:</strong> Print examples that show how integer and float division differ.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/numbers-in-ruby"
     data-practice-index="0"
     data-test="out = output.string; lines = out.lines.map(&:strip).reject(&:empty?); (lines.any? { |l| l.include?('.0') } || lines.any? { |l| l.match?(/\\d+\\.\\d+/) }) && lines.size >= 2"><code class="language-ruby">
# TODO: Print at least two results that highlight the difference
# between integer division and float division in Ruby.
# Hint:
#   - Try expressions like 7 / 2 and 7.0 / 2.
#   - Print each result on its own line.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/numbers-in-ruby"
     data-practice-index="0"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/numbers-in-ruby:0">
int_div  = 7 / 2
float_div = 7.0 / 2

puts "7 / 2   = #{int_div}"
puts "7.0 / 2 = #{float_div}"
</script>

#### Practice 2 - Modulo with positive and negative numbers

<p><strong>Goal:</strong> Experiment with the `%` operator using positive and negative operands.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/numbers-in-ruby"
     data-practice-index="1"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('%') } && lines.size >= 2"><code class="language-ruby">
# TODO: Print a few modulo calculations that use both positive and
# negative operands.
# Hint:
#   - Try 10 % 3, -10 % 3, and 10 % -3.
#   - Print each expression and its result.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/numbers-in-ruby"
     data-practice-index="1"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/numbers-in-ruby:1">
puts "10 % 3   = #{10 % 3}"
puts "-10 % 3  = #{-10 % 3}"
puts "10 % -3  = #{10 % -3}"
</script>

#### Practice 3 - Using ||= for defaults

<p><strong>Goal:</strong> Use the `||=` operator to set default configuration.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/numbers-in-ruby"
     data-practice-index="2"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('port') } && lines.any? { |l| l.match?(/\\d+/) }"><code class="language-ruby">
# TODO: Use ||= to set defaults for a few configuration values.
# Hint:
#   - Start with variables like port or host that might already
#     have a value.
#   - Use ||= to assign a default only when the value is nil.
#   - Print the final configuration so you can see the result.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/numbers-in-ruby"
     data-practice-index="2"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/numbers-in-ruby:2">
port = ENV["APP_PORT"]
port ||= 3000

host = ENV["APP_HOST"]
host ||= "localhost"

puts "port: #{port}"
puts "host: #{host}"
</script>

#### Practice 4 - and/&& precedence in assignments

<p><strong>Goal:</strong> Observe how `and` and `&&` differ when used with assignments.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/numbers-in-ruby"
     data-practice-index="3"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.match?(/and result: (true|false|nil)/) } && lines.any? { |l| l.match?(/&& result: (true|false|nil)/) }"><code class="language-ruby">
# TODO: Write a small script that uses both `and` and `&&` with
# assignments, then print out the results to compare.
# Hint:
#   - Try patterns like: value = true and other = false
#   - Repeat with && and print the assigned values.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/numbers-in-ruby"
     data-practice-index="3"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/numbers-in-ruby:3">
a = b = nil

a = true and b = false
puts "and result: a=#{a.inspect}, b=#{b.inspect}"

c = d = nil

c = true && d = false
puts "&& result: c=#{c.inspect}, d=#{d.inspect}"
</script>

Next up: apply these number skills while branching and iterating through collections.
