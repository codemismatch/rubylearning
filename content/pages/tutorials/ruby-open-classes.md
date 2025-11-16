---
layout: tutorial
title: "Chapter 28 &ndash; Ruby Open Classes"
permalink: /tutorials/ruby-open-classes/
difficulty: beginner
summary: Reopen existing classes--even core ones--to add behavior, and learn when to patch responsibly.
previous_tutorial:
  title: "Chapter 27: Including Other Files"
  url: /tutorials/including-other-files/
next_tutorial:
  title: "Chapter 29: Ruby Inheritance"
  url: /tutorials/ruby-inheritance/
related_tutorials:
  - title: "Writing Our Own Class"
    url: /tutorials/writing-our-own-class/
  - title: "Ruby Symbols"
    url: /tutorials/ruby-symbols/
---

> Adapted from Satish Talim's "Ruby Open Classes" lesson.

Ruby classes are **open**, meaning you can reopen them at any time to add or override methods--even built-in classes like `String` and `Integer`. This power fuels Ruby's expressive DSLs, but it requires discipline.

### Simple example: adding to `String`

<pre class="language-ruby"><code class="language-ruby">
class String
  def saysomething
    "Satish " + self
  end
end

puts "Talim".saysomething   #=> "Satish Talim"
</code></pre>

Reopening `String` lets every string gain the `saysomething` method.

### Monkey-patching other classes

You can extend numeric classes too:

<pre class="language-ruby"><code class="language-ruby">
class Integer
  def squared
    self * self
  end
end

puts 3.squared   #=&gt; 9
</code></pre>

This pattern explains why built-in methods like `2.times { ... }` work--the core `Integer` class defines them. Any method you add becomes available to every object of that class.

### Use responsibly

- Patches are global. Overriding a common method (e.g., `String#length`) affects all code, including gems.
- Prefer refinements or wrapper modules when shipping libraries to avoid collisions.
- Clearly document custom patches so teammates aren't surprised.

### Practice checklist

- [ ] Add a method to `Array` that returns the middle element, making sure odd/even sizes behave sensibly.
- [ ] Override `String#to_s` in a small script and observe the impact; revert afterward to avoid confusion.
- [ ] Implement a custom numeric helper (e.g., `5.minutes` returning seconds) and use it in a timer script.
- [ ] Explore refinements (`using ModuleName`) for safer, scoped patches.

Next: keep building in Flow Control & Collections, combining your augmented classes with loops and iterators, and then dive into Ruby Inheritance to organize related behavior.

#### Practice 1 - Adding Array#middle

<p><strong>Goal:</strong> Add a method to `Array` that returns the middle element, behaving sensibly for odd/even sizes.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-open-classes"
     data-practice-index="0"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('class Array') } && lines.any? { |l| l.include?('def middle') }"><code class="language-ruby">
# TODO: Reopen Array and define #middle so that it returns the middle
# element for odd sizes and one of the two middle elements for even
# sizes (you can choose which).
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-open-classes"
     data-practice-index="0"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-open-classes:0">
puts "class Array"
puts "  def middle"
puts "    return nil if empty?"
puts "    self[(size - 1) / 2]"
puts "  end"
puts "end"
</script>

#### Practice 2 - Overriding String#to_s

<p><strong>Goal:</strong> Override `String#to_s` in a small script and observe the impact.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-open-classes"
     data-practice-index="1"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('class String') } && lines.any? { |l| l.include?('def to_s') }"><code class="language-ruby">
# TODO: Print a small example that reopens String to override to_s and
# mention in a comment that this is only for experimentation.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-open-classes"
     data-practice-index="1"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-open-classes:1">
puts "class String"
puts "  def to_s"
puts "    \"[string: \#{inspect}]\""
puts "  end"
puts "end"
puts "# Override only in small scripts; avoid in real apps."
</script>

#### Practice 3 - Custom numeric helper

<p><strong>Goal:</strong> Implement a custom numeric helper (e.g., `5.minutes` returning seconds).</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-open-classes"
     data-practice-index="2"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('class Integer') } && lines.any? { |l| l.include?('def minutes') }"><code class="language-ruby">
# TODO: Reopen Integer and define minutes (and optionally seconds,
# hours) so that 5.minutes returns 300.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-open-classes"
     data-practice-index="2"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-open-classes:2">
puts "class Integer"
puts "  def minutes"
puts "    self * 60"
puts "  end"
puts "end"
puts "puts 5.minutes # => 300"
</script>

#### Practice 4 - Exploring refinements

<p><strong>Goal:</strong> Explore refinements for safer, scoped patches.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-open-classes"
     data-practice-index="3"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('refine String') } && lines.any? { |l| l.include?('using') }"><code class="language-ruby">
# TODO: Print a simple refinement that patches String inside a module
# and show how to activate it with using.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-open-classes"
     data-practice-index="3"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-open-classes:3">
puts "module StringRefinements"
puts "  refine String do"
puts "    def shout; upcase + '!'; end"
puts "  end"
puts "end"
puts "using StringRefinements"
puts "\"hello\".shout # works only where refinement is active"
</script>
