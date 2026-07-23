---
layout: tutorial
title: "Chapter 40 &ndash; Modules & Mixins"
permalink: /courses/ruby-basics/modules-and-mixins/
difficulty: intermediate
summary: Share behavior across classes by grouping methods in modules and mixing them in with `include` or `extend`.
previous_tutorial:
  title: "Chapter 39: Object Serialization (Marshal)"
  url: /courses/ruby-basics/object-serialization/
next_tutorial:
  title: "Chapter 41: Understanding `self`"
  url: /courses/ruby-basics/ruby-self/
related_tutorials:
  - title: "Ruby Open Classes"
    url: /courses/ruby-basics/ruby-open-classes/
  - title: "Ruby Inheritance"
    url: /courses/ruby-basics/ruby-inheritance/
---

> Adapted from Satish Talim's "Modules & Mixins" lesson.

Modules let you group related methods/constants and mix them into classes without multiple inheritance.

### `include` adds instance methods

```ruby-exec
module Honks
  def honk
    "honk!"
  end
end

class Car
  include Honks
end

puts Car.new.honk  #=> "honk!"
```

### `extend` adds class-level behavior

```ruby-exec
module Logging
  def log(message)
    puts "[#{name}] #{message}"
  end
end

class Service
  extend Logging
end

Service.log("Ready")  # class method
```

### Modules as namespaces

```ruby-exec
module Payments
  class Receipt; end
  end

  Payments::Receipt.new
```

Modules keep related classes/constants organized and prevent name clashes.

### Practice checklist

- [ ] Create a module with shared methods (`Flyable`) and include it in two unrelated classes.
- [ ] Use `extend` to add a class-level helper for logging.
- [ ] Define a namespace module (`Inventory`) containing multiple classes.
- [ ] Combine modules with inheritance--include different mixins in subclasses to tailor behavior.

Next: head back to Flow Control & Collections to deploy these shared behaviors in loops and enumerations.

#### Practice 1 - Sharing behaviour with an included module

**Goal:** Create a module with shared methods and include it in two unrelated classes.

#> ruby :practice

# TODO: Define a Flyable module with a take_off method, include it in
# two classes, and call the shared method on instances of each class.

```solution
module Flyable
  def take_off
    puts "#{self.class} is taking off"
  end
end

class Plane
  include Flyable
end

class Drone
  include Flyable
end

Plane.new.take_off
Drone.new.take_off
```

```test
out = output.string; lines = out.lines.map(&:strip).reject(&:empty?); lines.count { |l| l.downcase.include?('taking off') } >= 2
```

#!


#### Practice 2 - Using extend for class-level helpers

**Goal:** Use `extend` to add a class-level logging helper.

#> ruby :practice

# TODO: Create a module with a log class method and extend it into
# a class so you can call MyClass.log directly.

```solution
module ClassLogger
  def log(message)
    puts "LOG: #{message}"
  end
end

class Service
  extend ClassLogger
end

Service.log("starting up")
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('log:') }
```

#!


#### Practice 3 - Defining a namespace module

**Goal:** Define a namespace module containing multiple classes.

#> ruby :practice

# TODO: Build an Inventory module that contains Product and Order
# classes, then instantiate them using the namespace.

```solution
module Inventory
  class Product
    def initialize(name)
      @name = name
    end

    def label
      "Inventory::Product - #{@name}"
    end
  end

  class Order
    def initialize(id)
      @id = id
    end

    def label
      "Inventory::Order ##{@id}"
    end
  end
end

puts Inventory::Product.new("Book").label
puts Inventory::Order.new(1).label
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('Inventory::Product') } && lines.any? { |l| l.include?('Inventory::Order') }
```

#!


#### Practice 4 - Combining modules with inheritance

**Goal:** Include different mixins in subclasses to tailor behaviour.

#> ruby :practice

# TODO: Create a base class and two subclasses that each include
# different mixins to provide extra behaviour, then show the
# combined effects when you call their methods.

```solution
module EmailNotifications
  def notify(email)
    puts "emailing #{email}"
  end
end

module Logging
  def log(message)
    puts "logging: #{message}"
  end
end

class BaseJob
end

class SignupJob < BaseJob
  include EmailNotifications
end

class AuditJob < BaseJob
  include Logging
end

SignupJob.new.notify("user@example.com")
AuditJob.new.log("user signed up")
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('emailing') } && lines.any? { |l| l.downcase.include?('logging') }
```

#!

