---
layout: tutorial
title: "Chapter 11 &ndash; More on Ruby Methods"
permalink: /tutorials/more-on-ruby-methods/
difficulty: beginner
summary: See how Ruby dispatches methods, learn about the implicit receiver, and inspect `self` so you always know which object runs your code.
previous_tutorial:
  title: "Chapter 10: Ruby Names"
  url: /tutorials/ruby-names/
next_tutorial:
  title: "Chapter 12: Writing Your Own Ruby Methods"
  url: /tutorials/writing-own-ruby-methods/
related_tutorials:
  - title: "Methods & blocks"
    url: /tutorials/methods-and-blocks/
  - title: "Variables & Assignment"
    url: /tutorials/variables-and-assignment/
---

> Adapted from Satish Talim's "More on Ruby Methods" chapter.

If objects are the nouns of Ruby, methods are the verbs. Every method runs in the context of an object (the **receiver**). You usually see the receiver to the left of a dot (`message.upcase`), but Ruby also lets you call methods *without* writing the receiver explicitly.

### Explicit vs implicit receivers

<pre class="language-ruby" data-executable="true"><code class="language-ruby">
&quot;ruby&quot;.upcase    # receiver is the string literal
upcase           # same call, but the receiver is implicit
</code></pre>

When you omit the receiver, Ruby sends the message to the object referenced by `self`. At the top level of a script, `self` defaults to a special object named `main` that Ruby creates to represent your program.

<pre class="language-ruby" data-executable="true"><code class="language-ruby">
puts self        #=&gt; main
</code></pre>

Inside classes and modules, `self` changes depending on where you are:

<pre class="language-ruby" data-executable="true"><code class="language-ruby">
class Greeter
  puts &quot;Class body self: #{self}&quot;  # Greeter

  def greet
    puts &quot;Instance method self: #{self.inspect}&quot;
  end
end

Greeter.new.greet
</code></pre>

Understanding `self` helps you decide whether to call helper methods directly, qualify them with `self.`, or reach out to another object entirely.

### Methods are verbs on objects

Everything in Ruby is an object, so every expression you write ends up sending messages:

<pre class="language-ruby" data-executable="true"><code class="language-ruby">
42.to_s           # Integer -&gt; String
[1, 2, 3].length  # Array -&gt; Integer
ruby = &quot;Ruby&quot;
ruby.upcase!
</code></pre>

- Dot notation (`object.method`) makes the receiver obvious.
- Bang methods such as `upcase!` mutate the receiver; their non-bang counterparts return a new object.
- Predicate methods end with `?` (`empty?`, `include?`) and return true/false.

### Inspecting the current object

Use `self` whenever you need to check or pass the current receiver:

<pre class="language-ruby" data-executable="true"><code class="language-ruby">
def log_self
  puts &quot;Currently running inside #{self.class}: #{self.inspect}&quot;
end

log_self  # top-level =&gt; main
</code></pre>

Later chapters dive deeper into defining your own methods, but for now remember:

1. Every method belongs to a receiver.
2. Leaving off the receiver means "call this on `self`."
3. `self` changes based on where you are (top level, class body, instance method, etc.).

### Practice checklist

- [ ] Print `self` at the top level, inside a class body, and inside an instance method to watch it change.
- [ ] Rewrite a few explicit calls (e.g., `self.helper_method`) to implicit ones and confirm they still work.
- [ ] Experiment with predicate (`?`) and bang (`!`) method variants to see how they signal intent.
- [ ] Build a quick script that defines a helper method, calls it with and without an explicit receiver, and logs `self` along the way.

Next: apply these ideas in Flow Control & Collections, where you'll combine methods with loops and conditionals.

#### Practice 1 - Watching self in different contexts

<p><strong>Goal:</strong> Print `self` at the top level, inside a class body, and inside an instance method.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/more-on-ruby-methods"
     data-practice-index="0"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('top level') } && lines.any? { |l| l.downcase.include?('class body') } && lines.any? { |l| l.downcase.include?('instance method') }"><code class="language-ruby">
# TODO: Print self at the top level, inside a class body, and inside
# an instance method, labelling each line so you can see the context.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/more-on-ruby-methods"
     data-practice-index="0"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/more-on-ruby-methods:0">
puts "top level: #{self.inspect}"

class DemoSelf
  puts "class body: #{self.inspect}"

  def who_am_i
    puts "instance method: #{self.inspect}"
  end
end

DemoSelf.new.who_am_i
</script>

#### Practice 2 - Explicit vs implicit receivers

<p><strong>Goal:</strong> Rewrite explicit receiver calls to use implicit receivers and confirm they still work.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/more-on-ruby-methods"
     data-practice-index="1"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('explicit') } && lines.any? { |l| l.downcase.include?('implicit') }"><code class="language-ruby">
# TODO: Define a helper method and call it once with an explicit
# receiver (self.helper) and once without, printing labelled output
# for both calls.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/more-on-ruby-methods"
     data-practice-index="1"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/more-on-ruby-methods:1">
def helper
  "helper called"
end

puts "explicit: #{self.helper}"
puts "implicit: #{helper}"
</script>

#### Practice 3 - Predicate and bang methods

<p><strong>Goal:</strong> Experiment with predicate (`?`) and bang (`!`) method variants.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/more-on-ruby-methods"
     data-practice-index="2"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('empty?') } && lines.any? { |l| l.include?('upcase!') }"><code class="language-ruby">
# TODO: Use at least one predicate method and one bang method, and
# print before/after states to show how they differ.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/more-on-ruby-methods"
     data-practice-index="2"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/more-on-ruby-methods:2">
name = "ruby"

puts "empty? before: #{name.empty?}"

puts "before upcase!: #{name}"
name.upcase!
puts "after upcase!: #{name}"
</script>

#### Practice 4 - Logging self through helper calls

<p><strong>Goal:</strong> Define a helper method, call it with and without an explicit receiver, and log `self` along the way.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/more-on-ruby-methods"
     data-practice-index="3"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('helper called') } && lines.any? { |l| l.downcase.include?('self is') }"><code class="language-ruby">
# TODO: Build a short script that defines a helper method and logs
# self inside it, then call the helper with both explicit and
# implicit receivers, printing labelled lines.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/more-on-ruby-methods"
     data-practice-index="3"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/more-on-ruby-methods:3">
def helper_with_self(label)
  puts "#{label}: helper called, self is #{self.inspect}"
end

helper_with_self("implicit")
self.helper_with_self("explicit")
</script>
