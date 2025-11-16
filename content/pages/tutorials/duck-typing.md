---
layout: tutorial
title: "Chapter 36 &ndash; Duck Typing"
permalink: /tutorials/duck-typing/
difficulty: beginner
summary: Embrace Ruby's "if it quacks like a duck" philosophy-code to behavior, not class names.
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

> Adapted from Satish Talim's "Duck Typing" lesson.

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

#### Practice 1 - Calling duck-typed #swim

<p><strong>Goal:</strong> Write a function that calls `#swim` on different objects.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/duck-typing"
     data-practice-index="0"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.count { |l| l.downcase.include?('swimming') } >= 2"><code class="language-ruby">
# TODO: Define two simple classes that each implement #swim, then
# write a helper that accepts any object and calls swim on it.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/duck-typing"
     data-practice-index="0"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/duck-typing:0">
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
</script>

#### Practice 2 - Building an adapter with #notify

<p><strong>Goal:</strong> Build a wrapper that adds `#notify` to an object lacking it.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/duck-typing"
     data-practice-index="1"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('notified') }"><code class="language-ruby">
# TODO: Wrap a basic object in an adapter that provides a #notify
# method which delegates to an underlying implementation.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/duck-typing"
     data-practice-index="1"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/duck-typing:1">
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
</script>

#### Practice 3 - Duck-typed method_missing

<p><strong>Goal:</strong> Use `respond_to_missing?` and `method_missing` together to provide duck-typed behaviour.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/duck-typing"
     data-practice-index="2"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('handling swim') } && lines.any? { |l| l.downcase.include?('responds to :swim') }"><code class="language-ruby">
# TODO: Create a proxy object that handles a small set of dynamic
# methods via method_missing and accurately reports respond_to?
# using respond_to_missing?.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/duck-typing"
     data-practice-index="2"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/duck-typing:2">
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
</script>

#### Practice 4 - Focusing tests on behaviour

<p><strong>Goal:</strong> Combine duck typing with tests that check behaviour, not classes.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/duck-typing"
     data-practice-index="3"
     data-test="require 'test/unit/assertions'; extend Test::Unit::Assertions; out = output.string; assert out.lines.any? { |l| l.include?('quacks') }; true"><code class="language-ruby">
# TODO: Write a small snippet that checks whether an object responds
# to the methods you care about and prints a confirmation instead of
# inspecting its class.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/duck-typing"
     data-practice-index="3"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/duck-typing:3">
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
</script>
