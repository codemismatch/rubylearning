---
layout: tutorial
title: "Chapter 30 &ndash; Overriding Methods"
permalink: /tutorials/ruby-overriding-methods/
difficulty: intermediate
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

```ruby-exec
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
```

`super` with no parentheses forwards the original arguments automatically. Use `super()` to forward none, or `super(arg1, arg2)` for explicit control.

### Legacy motorcycle example

The original lesson used a `Motorcycle` base class and subclasses that override `#info`:

```ruby-exec
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
```

Feel free to stack overrides across multiple generations; each call to `super` climbs one level up the hierarchy.

### Practice checklist

- [ ] Build a `Vehicle` hierarchy with a base `#description` and override it in `Car` and `Truck`.
- [ ] Override `initialize` in a subclass and experiment with `super`, `super()`, and explicit argument lists.
- [ ] Add logging to an overridden method by printing before/after calling `super`.
- [ ] Combine overrides with modules: include a module that defines a method, then override it in the class to tweak output.

Next: keep exploring Flow Control & Collections, now with multiple levels of behavior you can toggle via overrides.

#### Practice 1 - Overriding #description

**Goal:** Build a `Vehicle` hierarchy with a base `#description` and override it in `Car` and `Truck`.

#> ruby :practice

# TODO: Define Vehicle#description and override it in Car and Truck
# to return specialised strings, then instantiate and print them.

```solution
class Vehicle
  def description
    "A generic vehicle"
  end
end

class Car < Vehicle
  def description
    super + " built for the road"
  end
end

class Truck < Vehicle
  def description
    super + " built for hauling cargo"
  end
end

puts Car.new.description
puts Truck.new.description
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('built for the road') } && lines.any? { |l| l.include?('hauling cargo') }
```

#!


#### Practice 2 - Overriding initialize with super variants

**Goal:** Override `initialize` in a subclass and experiment with `super`, `super()`, and explicit argument lists.

#> ruby :practice

# TODO: Sketch a base/subclass pair where the subclass uses both
# super and super() in different contexts and print labelled lines.

```solution
class Base
  def initialize(msg = "default")
    puts "Base initialized with #{msg}"
  end
end

class Child < Base
  def initialize(msg)
    puts "Child received: #{msg}"
    super(msg.upcase)
    super()
  end
end

Child.new("custom")
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('Child received') } && lines.count { |l| l.include?('Base initialized') } == 2
```

#!


#### Practice 3 - Logging around super

**Goal:** Add logging to an overridden method by printing before/after calling `super`.

#> ruby :practice

# TODO: Print an override that logs before and after calling super in
# a method such as #save.

```solution
class Model
  def save
    puts "Saving record"
  end
end

class LoggedModel < Model
  def save
    puts "before super"
    super
    puts "after super"
  end
end

LoggedModel.new.save
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('before super') } && lines.any? { |l| l.include?('after super') }
```

#!


#### Practice 4 - Overrides plus modules

**Goal:** Combine overrides with modules: include a module defining a method, then override it in the class.

#> ruby :practice

# TODO: Print a simple module with a greeting method, include it in a
# class, and override the method to tweak output while still calling
# super.

```solution
module Greeter
  def greet
    "hello"
  end
end

class Friendly
  include Greeter

  def greet
    super + ", friend"
  end
end

puts Friendly.new.greet
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('hello, friend') }
```

#!
