---
layout: tutorial
title: "Chapter 40 &ndash; Modules & Mixins"
permalink: /tutorials/modules-and-mixins/
difficulty: intermediate
summary: Share behavior across classes by grouping methods in modules and mixing them in with `include` or `extend`.
previous_tutorial:
  title: "Chapter 39: Object Serialization (Marshal)"
  url: /tutorials/object-serialization/
next_tutorial:
  title: "Chapter 41: Understanding `self`"
  url: /tutorials/ruby-self/
related_tutorials:
  - title: "Ruby Open Classes"
    url: /tutorials/ruby-open-classes/
  - title: "Ruby Inheritance"
    url: /tutorials/ruby-inheritance/
---

> Adapted from Satish Talim's "Modules & Mixins" lesson.

Modules let you group related methods/constants and mix them into classes without multiple inheritance.

### `include` adds instance methods

<pre class="language-ruby" data-executable="true"><code class="language-ruby">
module Honks
  def honk
    "honk!"
  end
end

class Car
  include Honks
end

puts Car.new.honk  #=> "honk!"
</code></pre>

### `extend` adds class-level behavior

<pre class="language-ruby" data-executable="true"><code class="language-ruby">
module Logging
  def log(message)
    puts &quot;[#{name}] #{message}&quot;
  end
end

class Service
  extend Logging
end

Service.log(&quot;Ready&quot;)  # class method
</code></pre>

### Modules as namespaces

<pre class="language-ruby" data-executable="true"><code class="language-ruby">
module Payments
  class Receipt; end
  end

  Payments::Receipt.new
</code></pre>

Modules keep related classes/constants organized and prevent name clashes.

### Practice checklist

- [ ] Create a module with shared methods (`Flyable`) and include it in two unrelated classes.
- [ ] Use `extend` to add a class-level helper for logging.
- [ ] Define a namespace module (`Inventory`) containing multiple classes.
- [ ] Combine modules with inheritance--include different mixins in subclasses to tailor behavior.

Next: head back to Flow Control & Collections to deploy these shared behaviors in loops and enumerations.

#### Practice 1 - Sharing behaviour with an included module

<p><strong>Goal:</strong> Create a module with shared methods and include it in two unrelated classes.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/modules-and-mixins"
     data-practice-index="0"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.count { |l| l.downcase.include?('taking off') } >= 2"><code class="language-ruby">
# TODO: Define a Flyable module with a take_off method, include it in
# two classes, and call the shared method on instances of each class.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/modules-and-mixins"
     data-practice-index="0"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/modules-and-mixins:0">
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
</script>

#### Practice 2 - Using extend for class-level helpers

<p><strong>Goal:</strong> Use `extend` to add a class-level logging helper.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/modules-and-mixins"
     data-practice-index="1"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('log:') }"><code class="language-ruby">
# TODO: Create a module with a log class method and extend it into
# a class so you can call MyClass.log directly.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/modules-and-mixins"
     data-practice-index="1"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/modules-and-mixins:1">
module ClassLogger
  def log(message)
    puts "LOG: #{message}"
  end
end

class Service
  extend ClassLogger
end

Service.log("starting up")
</script>

#### Practice 3 - Defining a namespace module

<p><strong>Goal:</strong> Define a namespace module containing multiple classes.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/modules-and-mixins"
     data-practice-index="2"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('Inventory::Product') } && lines.any? { |l| l.include?('Inventory::Order') }"><code class="language-ruby">
# TODO: Build an Inventory module that contains Product and Order
# classes, then instantiate them using the namespace.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/modules-and-mixins"
     data-practice-index="2"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/modules-and-mixins:2">
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
</script>

#### Practice 4 - Combining modules with inheritance

<p><strong>Goal:</strong> Include different mixins in subclasses to tailor behaviour.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/modules-and-mixins"
     data-practice-index="3"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('emailing') } && lines.any? { |l| l.downcase.include?('logging') }"><code class="language-ruby">
# TODO: Create a base class and two subclasses that each include
# different mixins to provide extra behaviour, then show the
# combined effects when you call their methods.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/modules-and-mixins"
     data-practice-index="3"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/modules-and-mixins:3">
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
</script>
