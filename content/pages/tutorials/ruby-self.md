---
layout: tutorial
title: "Chapter 41 &ndash; Understanding `self`"
permalink: /tutorials/ruby-self/
difficulty: beginner
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
