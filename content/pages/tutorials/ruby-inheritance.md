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

```ruby-exec
class Vehicle
  def start_engine
    "engine on"
  end
end

class Motorcycle < Vehicle
  def start_engine
    super + " vroom!"
  end
end

puts Motorcycle.new.start_engine  #=> "engine on vroom!"
```

- Use `<` to specify a superclass.
- Subclasses automatically inherit methods unless you override them.
- Call `super` (with or without arguments) to invoke the parent implementation.

### Constructor chaining

`initialize` follows the same rule: `super` passes control up the chain.

```ruby-exec
class Animal
  def initialize(name = nil)
    @name = name
  end
end

class Dog < Animal
  def initialize(name = nil, breed = nil)
    super(name)   # pass the name up to Animal
    @breed = breed
  end
end

puts Dog.new("Benzy", "Labrador").inspect
```

If you call `super` with empty parentheses (`super()`), Ruby forwards no arguments, giving you precise control.

### Mixing in modules

Ruby only allows single inheritance, but you can share behavior horizontally with modules. Legacy examples often defined reusable abilities (like `Honks` or `OffRoadable`) and mixed them into subclasses:

```ruby-exec
module OffRoadable
  def terrain
    "rocks and mud"
  end
end

class Jeep < Vehicle
  include OffRoadable
end

puts Jeep.new.terrain  #=> "rocks and mud"
```

Modules keep hierarchies shallow while still encouraging code reuse.

### Checking ancestry

- `obj.is_a?(ClassOrModule)` and its alias `kind_of?` respect inheritance and mixins.
- `obj.instance_of?(Class)` matches only the exact class--not subclasses.

```ruby-exec
dog = Dog.new("Benzy", "Labrador")

puts dog.is_a?(Animal)        # true
puts dog.instance_of?(Animal) # false
puts dog.instance_of?(Dog)    # true
```

Use the right predicate for the question you're asking.

### Practice checklist

- [ ] Extend the `Vehicle` hierarchy with `Car` and `Motorcycle`, overriding `start_engine` while calling `super`.
- [ ] Override `initialize` in a subclass and experiment with `super` vs `super()` to understand argument forwarding.
- [ ] Mix in a module (e.g., `Flyable`) to a subset of subclasses and confirm `is_a?` reflects the mixin.
- [ ] Use `instance_of?` vs `is_a?` to see how strict type checks affect control flow.

Next: continue to Flow Control & Collections to exercise these hierarchies inside loops and iterators.

#### Practice 1 - Extending the Vehicle hierarchy

**Goal:** Extend a `Vehicle` hierarchy with subclasses that override `start_engine` and call `super`.

#> ruby :practice

# TODO: Define a Vehicle base class with start_engine, then subclasses
# Car and Motorcycle that override start_engine while calling super.
# Instantiate each and call start_engine.

```solution
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
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('car engine') } && lines.any? { |l| l.downcase.include?('motorcycle engine') }
```

#!


#### Practice 2 - super vs super()

**Goal:** Override `initialize` in a subclass and experiment with `super` vs `super()`.

#> ruby :practice

# TODO: Build a small example that shows how super and super() behave
# differently when overriding initialize, and print labelled output.

```solution
class Base
  def initialize(arg = "default")
    puts "Base initialized with #{arg}"
  end
end

class WithArgs < Base
  def initialize(arg)
    puts "WithArgs calling super with args: #{arg}"
    super
  end
end

class WithoutArgs < Base
  def initialize(arg)
    puts "WithoutArgs calling super() without args (ignoring #{arg})"
    super()
  end
end

WithArgs.new("custom")
WithoutArgs.new("ignored")
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('with args') } && lines.any? { |l| l.downcase.include?('without args') }
```

#!


#### Practice 3 - Mixins and is_a?

**Goal:** Mix a module into a subset of subclasses and confirm `is_a?` reflects the mixin.

#> ruby :practice

# TODO: Define a Flyable module, include it in one subclass, and print
# a line proving that instance.is_a?(Flyable) is true.

```solution
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
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('can fly') } && lines.any? { |l| l.downcase.include?('is a flyable') }
```

#!


#### Practice 4 - instance_of? vs is_a?

**Goal:** Compare `instance_of?` vs `is_a?` and see how strict type checks affect control flow.

#> ruby :practice

# TODO: Create a base class and subclass, instantiate the subclass,
# and print the results of instance_of? and is_a? checks.

```solution
class Creature; end
class Cat < Creature; end

cat = Cat.new
puts "instance_of? Cat: #{cat.instance_of?(Cat)}"
puts "instance_of? Creature: #{cat.instance_of?(Creature)}"
puts "is_a? Creature: #{cat.is_a?(Creature)}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('instance_of?') } && lines.any? { |l| l.include?('is_a?') }
```

#!
