---
layout: tutorial
title: "Chapter 40 &ndash; Modules & Mixins"
permalink: /tutorials/modules-and-mixins/
difficulty: beginner
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

<pre class="language-ruby"><code class="language-ruby">
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

<pre class="language-ruby"><code class="language-ruby">
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

<pre class="language-ruby"><code class="language-ruby">
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
