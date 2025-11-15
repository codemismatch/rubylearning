---
layout: tutorial
title: "Chapter 30 &ndash; Overriding Methods"
permalink: /tutorials/ruby-overriding-methods/
difficulty: beginner
summary: Customize inherited behavior by overriding methods and using `super` to build on parent logic.
previous_tutorial:
  title: "Chapter 29: Ruby Inheritance"
  url: /tutorials/ruby-inheritance/
next_tutorial:
  title: 'Chapter 31: "Overloading" Methods the Ruby Way'
  url: /tutorials/ruby-overloading-methods/
related_tutorials:
  - title: "Writing Our Own Class"
    url: /tutorials/writing-our-own-class/
  - title: "Ruby Open Classes"
    url: /tutorials/ruby-open-classes/
---

> Adapted from Satish Talim's "Overriding Methods" lesson.

Inheritance gives you defaults; overriding lets subclasses tailor those defaults. Ruby makes overriding straightforward: define a method with the same name in the subclass, and call `super` when you need the parent's behavior.

### Basic override

<pre class="language-ruby"><code class="language-ruby">
class Animal
  def speak
    "generic noise"
  end
end

class Dog < Animal
  def speak
    super + " ruff"
  end
end

puts Animal.new.speak  #=> "generic noise"
puts Dog.new.speak     #=> "generic noise ruff"
</code></pre>

`super` with no parentheses forwards the original arguments automatically. Use `super()` to forward none, or `super(arg1, arg2)` for explicit control.

### Legacy motorcycle example

The original lesson used a `Motorcycle` base class and subclasses that override `#info`:

<pre class="language-ruby"><code class="language-ruby">
class Motorcycle
  def info
    "Two wheels, generic motorcycle"
  end
end

class SportsBike < Motorcycle
  def info
    super + " tuned for speed"
  end
end

puts SportsBike.new.info
</code></pre>

Feel free to stack overrides across multiple generations; each call to `super` climbs one level up the hierarchy.

### Practice checklist

- [ ] Build a `Vehicle` hierarchy with a base `#description` and override it in `Car` and `Truck`.
- [ ] Override `initialize` in a subclass and experiment with `super`, `super()`, and explicit argument lists.
- [ ] Add logging to an overridden method by printing before/after calling `super`.
- [ ] Combine overrides with modules: include a module that defines a method, then override it in the class to tweak output.

Next: keep exploring Flow Control & Collections, now with multiple levels of behavior you can toggle via overrides.
