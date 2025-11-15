---
layout: tutorial
title: "Chapter 29 &ndash; Ruby Inheritance"
permalink: /tutorials/ruby-inheritance/
difficulty: beginner
summary: Reuse behavior by deriving subclasses, chaining `super`, and checking object ancestry.
previous_tutorial:
  title: "Chapter 28: Ruby Open Classes"
  url: /tutorials/ruby-open-classes/
next_tutorial:
  title: "Chapter 30: Overriding Methods"
  url: /tutorials/ruby-overriding-methods/
related_tutorials:
  - title: "Writing Our Own Class"
    url: /tutorials/writing-our-own-class/
  - title: "Ruby Procs & Lambdas"
    url: /tutorials/ruby-procs/
---

> Adapted from Satish Talim's "Ruby Inheritance" lesson.

Inheritance lets you derive a class from another, sharing behavior while customizing it. Every Ruby class ultimately inherits from `Object` (and, one level deeper, `BasicObject`), so even a "blank" class automatically picks up dozens of handy methods.

### Defining a hierarchy

<pre class="language-ruby"><code class="language-ruby">
class Vehicle
  def start_engine
    &quot;engine on&quot;
  end
end

class Motorcycle &lt; Vehicle
  def start_engine
    super + &quot; vroom!&quot;
  end
end

puts Motorcycle.new.start_engine  #=&gt; &quot;engine on vroom!&quot;
</code></pre>

- Use `<` to specify a superclass.
- Subclasses automatically inherit methods unless you override them.
- Call `super` (with or without arguments) to invoke the parent implementation.

### Constructor chaining

`initialize` follows the same rule: `super` passes control up the chain.

<pre class="language-ruby"><code class="language-ruby">
class Animal
  def initialize(name)
    @name = name
  end
end

class Dog &lt; Animal
  def initialize(name, breed)
    super(name)   # pass the name up to Animal
    @breed = breed
  end
end

puts Dog.new("Benzy", "Labrador").inspect
</code></pre>

If you call `super` with empty parentheses (`super()`), Ruby forwards no arguments, giving you precise control.

### Mixing in modules

Ruby only allows single inheritance, but you can share behavior horizontally with modules. Legacy examples often defined reusable abilities (like `Honks` or `OffRoadable`) and mixed them into subclasses:

<pre class="language-ruby"><code class="language-ruby">
module OffRoadable
  def terrain
    "rocks and mud"
  end
end

class Jeep < Vehicle
  include OffRoadable
end

puts Jeep.new.terrain  #=> "rocks and mud"
</code></pre>

Modules keep hierarchies shallow while still encouraging code reuse.

### Checking ancestry

- `obj.is_a?(ClassOrModule)` and its alias `kind_of?` respect inheritance and mixins.
- `obj.instance_of?(Class)` matches only the exact class--not subclasses.

<pre class="language-ruby"><code class="language-ruby">
dog = Dog.new(&quot;Benzy&quot;, &quot;Labrador&quot;)

puts dog.is_a?(Animal)        # true
puts dog.instance_of?(Animal) # false
puts dog.instance_of?(Dog)    # true
</code></pre>

Use the right predicate for the question you're asking.

### Practice checklist

- [ ] Extend the `Vehicle` hierarchy with `Car` and `Motorcycle`, overriding `start_engine` while calling `super`.
- [ ] Override `initialize` in a subclass and experiment with `super` vs `super()` to understand argument forwarding.
- [ ] Mix in a module (e.g., `Flyable`) to a subset of subclasses and confirm `is_a?` reflects the mixin.
- [ ] Use `instance_of?` vs `is_a?` to see how strict type checks affect control flow.

Next: continue to Flow Control & Collections to exercise these hierarchies inside loops and iterators.
