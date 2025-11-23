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
    "A car for the road"
  end
end

class Truck < Vehicle
  def description
    "A truck for hauling"
  end
end

puts Car.new.description
puts Truck.new.description
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('car for the road') } && lines.any? { |l| l.downcase.include?('truck for hauling') }
```

#!


#### Practice 2 - Overriding initialize with super variants

**Goal:** Override `initialize` in a subclass and experiment with `super`, `super()`, and explicit argument lists.

#> ruby :practice

# TODO: Sketch a base/subclass pair where the subclass uses both
# super and super() in different contexts and print labelled lines.

```solution
puts "class Base"
puts "  def initialize(msg = 'default')"
puts "    puts \"Base: \#{msg}\""
puts "  end"
puts "end"
puts "class Child < Base"
puts "  def initialize(msg)"
puts "    super(msg)"
puts "    super() # uses default argument"
puts "  end"
puts "end"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('super()') } && lines.any? { |l| l.downcase.include?('super with args') }
```

#!


#### Practice 3 - Logging around super

**Goal:** Add logging to an overridden method by printing before/after calling `super`.

#> ruby :practice

# TODO: Print an override that logs before and after calling super in
# a method such as #save.

```solution
puts "class Model"
puts "  def save"
puts "    puts 'Saving record'"
puts "  end"
puts "end"
puts "class LoggedModel < Model"
puts "  def save"
puts "    puts 'before super'"
puts "    super"
puts "    puts 'after super'"
puts "  end"
puts "end"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('before super') } && lines.any? { |l| l.downcase.include?('after super') }
```

#!


#### Practice 4 - Overrides plus modules

**Goal:** Combine overrides with modules: include a module defining a method, then override it in the class.

#> ruby :practice

# TODO: Print a simple module with a greeting method, include it in a
# class, and override the method to tweak output while still calling
# super.

```solution
puts "module Greeter"
puts "  def greet"
puts "    'hello'"
puts "  end"
puts "end"
puts "class Friendly"
puts "  include Greeter"
puts "  def greet"
puts "    super + ', friend'"
puts "  end"
puts "end"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('module') } && lines.any? { |l| l.downcase.include?('override') }
```

#!

