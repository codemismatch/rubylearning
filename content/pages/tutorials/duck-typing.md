---
layout: tutorial
title: "Chapter 36 &ndash; Duck Typing"
permalink: /tutorials/duck-typing/
difficulty: beginner
summary: Embrace Ruby’s “if it quacks like a duck” philosophy—code to behavior, not class names.
previous_tutorial:
  title: "Chapter 35: Ruby Time Class"
  url: /tutorials/ruby-time-class/
next_tutorial:
  title: "Chapter 37: Ruby Syntactic Sugar"
  url: /tutorials/ruby-syntactic-sugar/
related_tutorials:
  - title: "Ruby Access Control"
    url: /tutorials/ruby-access-control/
  - title: "Ruby `method_missing`"
    url: /tutorials/ruby-method-missing/
---

> Adapted from Satish Talim’s “Duck Typing” lesson.

Duck typing says: *if it quacks like a duck, treat it like a duck.* Ruby cares about the methods an object responds to, not its class name.

### Simple example

<pre class="language-ruby"><code class="language-ruby">
def make_it_quack(thing)
  thing.quack
end

class Duck
  def quack
    puts "Quack!"
  end
end

class Person
  def quack
    puts "Pretending to be a duck"
  end
end

make_it_quack(Duck.new)
make_it_quack(Person.new)
</code></pre>

Both objects implement `#quack`, so the method works for either type.

### Using `respond_to?`

Use `respond_to?` when you want to guard against missing behavior:

<pre class="language-ruby"><code class="language-ruby">
def notify(target, message)
  if target.respond_to?(:notify)
    target.notify(message)
  else
    raise ArgumentError, &quot;Target must respond to #notify&quot;
  end
end
</code></pre>

Adapters can wrap third-party objects to conform to the expected interface.

### Practice checklist

- [ ] Write a function that calls `#swim` and pass different objects (fish, robot) that implement it.
- [ ] Build a wrapper that adds `#notify` to an object lacking it, demonstrating an adapter.
- [ ] Use `respond_to_missing?` and `method_missing` together to provide duck-typed behavior.
- [ ] Combine duck typing with unit tests: ensure your custom objects respond to the needed methods rather than checking classes.

Next: keep iterating through Flow Control & Collections, now coding to behavior instead of rigid hierarchies.
