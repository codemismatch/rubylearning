---
layout: tutorial
title: "Chapter 36 &ndash; Duck Typing"
permalink: /courses/ruby-basics/duck-typing/
difficulty: intermediate
summary: Embrace Ruby's "if it quacks like a duck" philosophy-code to behavior, not class names.
previous_tutorial:
  title: "Chapter 35: Ruby Time Class"
  url: /courses/ruby-basics/ruby-time-class/
next_tutorial:
  title: "Chapter 37: Ruby Syntactic Sugar"
  url: /courses/ruby-basics/ruby-syntactic-sugar/
related_tutorials:
  - title: "Ruby Access Control"
    url: /courses/ruby-basics/ruby-access-control/
  - title: "Ruby `method_missing`"
    url: /courses/ruby-basics/ruby-method-missing/
---

> Adapted from Satish Talim's "Duck Typing" lesson.

Duck typing says: *if it quacks like a duck, treat it like a duck.* Ruby cares about the methods an object responds to, not its class name.

### Simple example

```ruby-exec
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
```

Both objects implement `#quack`, so the method works for either type.

### Using `respond_to?`

Use `respond_to?` when you want to guard against missing behavior:

```ruby-exec
def notify(target, message)
  if target.respond_to?(:notify)
    target.notify(message)
  else
    raise ArgumentError, "Target must respond to #notify"
  end
end
```

Adapters can wrap third-party objects to conform to the expected interface.

### Practice checklist

- [ ] Write a function that calls `#swim` and pass different objects (fish, robot) that implement it.
- [ ] Build a wrapper that adds `#notify` to an object lacking it, demonstrating an adapter.
- [ ] Use `respond_to_missing?` and `method_missing` together to provide duck-typed behavior.
- [ ] Combine duck typing with unit tests: ensure your custom objects respond to the needed methods rather than checking classes.

Next: keep iterating through Flow Control & Collections, now coding to behavior instead of rigid hierarchies.

#### Practice 1 - Calling duck-typed #swim

**Goal:** Write a function that calls `#swim` on different objects.

#> ruby :practice

# TODO: Define two simple classes that each implement #swim, then
# write a helper that accepts any object and calls swim on it.

```solution
class Fish
  def swim
    puts "Fish is swimming"
  end
end

class Robot
  def swim
    puts "Robot is swimming"
  end
end

def make_it_swim(creature)
  creature.swim
end

make_it_swim(Fish.new)
make_it_swim(Robot.new)
```

```test
out = output.string; lines = out.lines.map(&:strip).reject(&:empty?); lines.count { |l| l.downcase.include?('swimming') } >= 2
```

#!


#### Practice 2 - Building an adapter with #notify

**Goal:** Build a wrapper that adds `#notify` to an object lacking it.

#> ruby :practice

# TODO: Wrap a basic object in an adapter that provides a #notify
# method which delegates to an underlying implementation.

```solution
class BasicClient
  def send_message(text)
    puts "sending: #{text}"
  end
end

class NotifyingClient
  def initialize(client)
    @client = client
  end

  def notify(text)
    @client.send_message(text)
    puts "notified!"
  end
end

wrapped = NotifyingClient.new(BasicClient.new)
wrapped.notify("Hello")
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('notified') }
```

#!


#### Practice 3 - Duck-typed method_missing

**Goal:** Use `respond_to_missing?` and `method_missing` together to provide duck-typed behaviour.

#> ruby :practice

# TODO: Create a proxy object that handles a small set of dynamic
# methods via method_missing and accurately reports respond_to?
# using respond_to_missing?.

```solution
class SwimProxy
  def method_missing(name, *args, &block)
    if name == :swim
      puts "handling swim via method_missing"
    else
      super
    end
  end

  def respond_to_missing?(name, include_private = false)
    name == :swim || super
  end
end

proxy = SwimProxy.new
proxy.swim
puts "responds to :swim? #{proxy.respond_to?(:swim)}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('handling swim') } && lines.any? { |l| l.downcase.include?('responds to :swim') }
```

#!


#### Practice 4 - Focusing tests on behaviour

**Goal:** Combine duck typing with tests that check behaviour, not classes.

#> ruby :practice

# TODO: Write a small snippet that checks whether an object responds
# to the methods you care about and prints a confirmation instead of
# inspecting its class.

```solution
class DuckLike
  def quack
    "quacks"
  end
end

obj = DuckLike.new

if obj.respond_to?(:quack)
  puts obj.quack
else
  puts "object cannot quack"
end
```

```test
out = output.string; out.lines.any? { |l| l.include?('quacks') }
```

#!

