---
layout: tutorial
title: "Chapter 18 &ndash; Ruby Ranges"
permalink: /tutorials/ruby-ranges/
difficulty: beginner
summary: Use inclusive/exclusive ranges to model sequences, iterate efficiently, and perform interval tests with `===`.
previous_tutorial:
  title: "Chapter 17: Ruby Arrays"
  url: /tutorials/ruby-arrays/
next_tutorial:
  title: "Chapter 19: Ruby Symbols"
  url: /tutorials/ruby-symbols/
related_tutorials:
  - title: "Flow control & collections"
    url: /tutorials/flow-control-collections/
  - title: "Simple Constructs"
    url: /tutorials/simple-constructs/
---

> Adapted from Satish Talim's original ranges lesson.

Ranges represent sequences with a start, an end, and a way to produce successive values. They're light-weight objects that reference the boundary values rather than allocating every member up front.

### Inclusive vs exclusive ranges

- `..` (two dots) creates an inclusive range containing the high value.
- `...` (three dots) excludes the high value.

<pre class="language-ruby"><code class="language-ruby">
(1..5).to_a    #=&gt; [1, 2, 3, 4, 5]
(1...5).to_a   #=&gt; [1, 2, 3, 4]
</code></pre>

Ranges aren't stored as arrays internally--`1..100_000` keeps just the endpoints--but you can convert one to an array with `to_a` when needed.

### Common helpers

<pre class="language-ruby"><code class="language-ruby">
# p021ranges.rb
digits = -1..9
puts digits.include?(5)          # true
puts digits.min                  # -1
puts digits.max                  # 9
puts digits.reject { |i| i < 5 } # [5, 6, 7, 8, 9]
</code></pre>

Because ranges mix in `Enumerable`, you get iterators like `each`, `map`, `reject`, and friends out of the box.

### Interval testing with `===`

Ranges shine when checking if a value falls within a specific interval. Use the case-equality operator (`===`), which also powers `case` statements:

<pre class="language-ruby"><code class="language-ruby">
(1..10) === 5        # true
(1..10) === 15       # false
(1..10) === 3.14159  # true
(&quot;a&quot;..&quot;j&quot;) === &quot;c&quot;   # true
(&quot;a&quot;..&quot;j&quot;) === &quot;z&quot;   # false
</code></pre>

Drop ranges directly into `case` expressions for readable branching:

<pre class="language-ruby"><code class="language-ruby">
grade = 87
label = case grade
when 90..100 then &quot;A&quot;
when 80...90 then &quot;B&quot;
else &quot;Needs work&quot;
end
</code></pre>

### Practice checklist

- [ ] Convert `(1..10)` and `(1...10)` to arrays and compare the results.
- [ ] Use `include?`, `min`, and `max` on a negative-to-positive range.
- [ ] Write a method that accepts a range and yields only the even members via `select`.
- [ ] Build a `case` expression that classifies temperatures using range intervals.

Next: continue into Flow Control & Collections where ranges, arrays, and enumerators come together in loops and iterators.

#### Practice 1 - Inclusive vs exclusive ranges

<p><strong>Goal:</strong> Convert `(1..10)` and `(1...10)` to arrays and compare the results.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-ranges"
     data-practice-index="0"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('1..10') } && lines.any? { |l| l.include?('1...10') }"><code class="language-ruby">
# TODO: Print the arrays produced by (1..10).to_a and (1...10).to_a
# with clear labels.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-ranges"
     data-practice-index="0"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-ranges:0">
puts "1..10  => #{(1..10).to_a.inspect}"
puts "1...10 => #{(1...10).to_a.inspect}"
</script>

#### Practice 2 - include?, min, max on ranges

<p><strong>Goal:</strong> Use `include?`, `min`, and `max` on a negative-to-positive range.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-ranges"
     data-practice-index="1"
     data-test="out = output.string; lines = out.lines.map(&:strip); %w[include? min max].all? { |m| lines.any? { |l| l.include?(m) } }"><code class="language-ruby">
# TODO: Create a range from -5 to 5 and print whether it includes 0,
# along with its min and max.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-ranges"
     data-practice-index="1"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-ranges:1">
range = -5..5
puts "include?(0): #{range.include?(0)}"
puts "min: #{range.min}, max: #{range.max}"
</script>

#### Practice 3 - Yielding even members from a range

<p><strong>Goal:</strong> Write a method that accepts a range and yields only the even members using `select`.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-ranges"
     data-practice-index="2"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('even') }"><code class="language-ruby">
# TODO: Print an example method that takes a range and returns only
# its even numbers with select.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-ranges"
     data-practice-index="2"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-ranges:2">
puts "def evens(range)"
puts "  range.select(&:even?)"
puts "end"
</script>

#### Practice 4 - case with range intervals

<p><strong>Goal:</strong> Build a `case` expression that classifies temperatures using ranges.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-ranges"
     data-practice-index="3"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('cold') } && lines.any? { |l| l.downcase.include?('hot') }"><code class="language-ruby">
# TODO: Print a case expression that categorises a temperature as
# cold, mild, or hot using range intervals.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-ranges"
     data-practice-index="3"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-ranges:3">
puts "case temp"
puts "when -50...10 then 'cold'"
puts "when 10...25 then 'mild'"
puts "else 'hot'"
puts "end"
</script>
