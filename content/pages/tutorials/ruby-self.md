---
layout: tutorial
title: "Chapter 41 &ndash; Understanding `self`"
permalink: /tutorials/ruby-self/
difficulty: intermediate
summary: "`self` always points to the current object--learn how it shifts between top-level code, class bodies, and methods."
previous_tutorial:
  title: "Chapter 40: Modules & Mixins"
  url: /tutorials/modules-and-mixins/
next_tutorial:
  title: "Chapter 42: Ruby Constants"
  url: /tutorials/ruby-constants/
related_tutorials:
  - title: "Writing Our Own Class"
    url: /tutorials/writing-our-own-class/
  - title: "Ruby Open Classes"
    url: /tutorials/ruby-open-classes/
---

> Adapted from Satish Talim's "Ruby self" lesson.

`self` always references "the current object," but that object changes depending on where you are in the code.

### Top-level `self`

At the top level of a file:

<pre class="language-ruby"><code class="language-ruby">
puts self        #=&gt; main
puts self.class  #=&gt; Object
</code></pre>

`main` is an instance of `Object` that Ruby uses to evaluate top-level code.

### Inside class definitions

Within the class body (outside instance methods), `self` is the class object:

<pre class="language-ruby"><code class="language-ruby">
class Person
  puts self        #=&gt; Person
  def instance_method
    puts self.inspect
  end

  def self.class_method
    puts self      #=&gt; Person
  end
end

Person.new.instance_method #=&gt; #&lt;Person:...&gt;
Person.class_method        #=&gt; Person
</code></pre>

- Instance methods: `self` is the receiver (the instance).
- Class methods: `self` is the class itself.

### Practice checklist

- [ ] Print `self` in top-level code, inside a class body, inside an instance method, and inside a class method.
- [ ] Define a module and print `self` within `module` scope to see how it becomes the module object.
- [ ] Use `instance_eval` or `class << self` to explore how `self` shifts in singleton/class contexts.
- [ ] Combine with `method_missing` or `respond_to?` to see how `self` affects dynamic behavior.

Next: keep iterating through Flow Control & Collections, now confident about who `self` is in every context.

#### Practice 1 - self in common contexts

<p><strong>Goal:</strong> Print `self` in top-level code, inside a class body, inside an instance method, and inside a class method.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-self"
     data-practice-index="0"
     data-test="out = output.string; lines = out.lines.map(&:strip); %w[top-level class-body instance-method class-method].all? { |label| lines.any? { |l| l.downcase.include?(label) } }"><code class="language-ruby">
# TODO: Print labelled lines for self in the four contexts described
# above so you can compare them.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-self"
     data-practice-index="0"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-self:0">
puts "top-level: #{self.inspect}"

class SelfDemo
  puts "class-body: #{self.inspect}"

  def instance_example
    puts "instance-method: #{self.inspect}"
  end

  def self.class_example
    puts "class-method: #{self.inspect}"
  end
end

SelfDemo.new.instance_example
SelfDemo.class_example
</script>

#### Practice 2 - self in module scope

<p><strong>Goal:</strong> Define a module and print `self` within module scope.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-self"
     data-practice-index="1"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('module scope') }"><code class="language-ruby">
# TODO: Sketch a module that prints self from within its body to show
# that self is the module object there.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-self"
     data-practice-index="1"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-self:1">
puts "module ModuleDemo"
puts "  puts \"module scope: \#{self.inspect}\""
puts "end"
</script>

#### Practice 3 - instance_eval and class << self

<p><strong>Goal:</strong> Use `instance_eval` or `class << self` to explore how `self` shifts in singleton/class contexts.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-self"
     data-practice-index="2"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('instance_eval') } && lines.any? { |l| l.downcase.include?('class << self') }"><code class="language-ruby">
# TODO: Print an example using instance_eval and class << self that
# shows self changing inside each context.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-self"
     data-practice-index="2"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-self:2">
puts "obj = Object.new"
puts "obj.instance_eval { puts \"instance_eval self: \#{self.inspect}\" }"
puts "class SingletonDemo"
puts "  class << self"
puts "    puts \"class << self: \#{self.inspect}\""
puts "  end"
puts "end"
</script>

#### Practice 4 - self with dynamic behaviour

<p><strong>Goal:</strong> Combine `self` with `respond_to?` to see how `self` affects dynamic behavior.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-self"
     data-practice-index="3"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('respond_to?') }"><code class="language-ruby">
# TODO: Print a small dynamic call that uses respond_to? on self before
# sending a message.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-self"
     data-practice-index="3"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-self:3">
puts "if self.respond_to?(:to_str)"
puts "  puts 'self responds to to_str'"
puts "end"
</script>
