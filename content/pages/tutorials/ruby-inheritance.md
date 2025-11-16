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

#### Practice 1 - Extending the Vehicle hierarchy

<p><strong>Goal:</strong> Extend a `Vehicle` hierarchy with subclasses that override `start_engine` and call `super`.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-inheritance"
     data-practice-index="0"
     data-test="require 'test/unit/assertions'; extend Test::Unit::Assertions; sandbox.const_defined?(:Vehicle) && sandbox.const_defined?(:Car) && sandbox.const_defined?(:Motorcycle); v = sandbox.const_get(:Vehicle).new; c = sandbox.const_get(:Car).new; m = sandbox.const_get(:Motorcycle).new; out = output.string; assert out.lines.any? { |l| l.downcase.include?('car') }; assert out.lines.any? { |l| l.downcase.include?('motorcycle') }; true"><code class="language-ruby">
# TODO: Define a Vehicle base class with start_engine, then subclasses
# Car and Motorcycle that override start_engine while calling super.
# Instantiate each and call start_engine.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-inheritance"
     data-practice-index="0"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-inheritance:0">
class Vehicle
  def start_engine
    puts "Starting generic engine"
  end
end

class Car < Vehicle
  def start_engine
    super
    puts "Car engine is now running"
  end
end

class Motorcycle < Vehicle
  def start_engine
    super
    puts "Motorcycle engine is now running"
  end
end

Vehicle.new.start_engine
Car.new.start_engine
Motorcycle.new.start_engine
</script>

#### Practice 2 - super vs super()

<p><strong>Goal:</strong> Override `initialize` in a subclass and experiment with `super` vs `super()`.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-inheritance"
     data-practice-index="1"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('with args') } && lines.any? { |l| l.downcase.include?('without args') }"><code class="language-ruby">
# TODO: Build a small example that shows how super and super() behave
# differently when overriding initialize, and print labelled output.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-inheritance"
     data-practice-index="1"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-inheritance:1">
class Base
  def initialize(arg = "default")
    puts "Base initialized with #{arg}"
  end
end

class WithArgs < Base
  def initialize(arg)
    puts "WithArgs before super"
    super
  end
end

class WithoutArgs < Base
  def initialize(arg)
    puts "WithoutArgs before super()"
    super()
  end
end

WithArgs.new("with args")
WithoutArgs.new("ignored")
</script>

#### Practice 3 - Mixins and is_a?

<p><strong>Goal:</strong> Mix a module into a subset of subclasses and confirm `is_a?` reflects the mixin.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-inheritance"
     data-practice-index="2"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('can fly') } && lines.any? { |l| l.downcase.include?('is a flyable') }"><code class="language-ruby">
# TODO: Define a Flyable module, include it in one subclass, and print
# a line proving that instance.is_a?(Flyable) is true.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-inheritance"
     data-practice-index="2"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-inheritance:2">
module Flyable
  def fly
    puts "#{self.class} can fly"
  end
end

class Plane
  include Flyable
end

plane = Plane.new
plane.fly
puts "is a Flyable? #{plane.is_a?(Flyable)}"
</script>

#### Practice 4 - instance_of? vs is_a?

<p><strong>Goal:</strong> Compare `instance_of?` vs `is_a?` and see how strict type checks affect control flow.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-inheritance"
     data-practice-index="3"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('instance_of?') } && lines.any? { |l| l.include?('is_a?') }"><code class="language-ruby">
# TODO: Create a base class and subclass, instantiate the subclass,
# and print the results of instance_of? and is_a? checks.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-inheritance"
     data-practice-index="3"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-inheritance:3">
class Animal; end
class Dog < Animal; end

dog = Dog.new
puts "instance_of? Dog: #{dog.instance_of?(Dog)}"
puts "instance_of? Animal: #{dog.instance_of?(Animal)}"
puts "is_a? Animal: #{dog.is_a?(Animal)}"
</script>
