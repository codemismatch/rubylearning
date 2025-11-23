---
layout: tutorial
title: "Chapter 11 &ndash; More on Ruby Methods"
permalink: /tutorials/more-on-ruby-methods/
difficulty: beginner
summary: See how Ruby dispatches methods, learn about the implicit receiver, and inspect `self` so you always know which object runs your code.
previous_tutorial:
  title: "Chapter 10: Ruby Names"
  url: /tutorials/ruby-names/
next_tutorial:
  title: "Chapter 12: Writing Your Own Ruby Methods"
  url: /tutorials/writing-own-ruby-methods/
related_tutorials:
  - title: "Methods & blocks"
    url: /tutorials/methods-and-blocks/
  - title: "Variables & Assignment"
    url: /tutorials/variables-and-assignment/
---

> Adapted from Satish Talim's "More on Ruby Methods" chapter.

If objects are the nouns of Ruby, methods are the verbs. Every method runs in the context of an object (the **receiver**). You usually see the receiver to the left of a dot (`message.upcase`), but Ruby also lets you call methods *without* writing the receiver explicitly.

### Explicit vs implicit receivers

```ruby-exec
"ruby".upcase    # receiver is the string literal
upcase           # same call, but the receiver is implicit
```

When you omit the receiver, Ruby sends the message to the object referenced by `self`. At the top level of a script, `self` defaults to a special object named `main` that Ruby creates to represent your program.

```ruby-exec
puts self        #=> main
```

Inside classes and modules, `self` changes depending on where you are:

```ruby-exec
class Greeter
  puts "Class body self: #{self}"  # Greeter

  def greet
    puts "Instance method self: #{self.inspect}"
  end
end

Greeter.new.greet
```

Understanding `self` helps you decide whether to call helper methods directly, qualify them with `self.`, or reach out to another object entirely.

### Methods are verbs on objects

Everything in Ruby is an object, so every expression you write ends up sending messages:

```ruby-exec
42.to_s           # Integer -> String
[1, 2, 3].length  # Array -> Integer
ruby = "Ruby"
ruby.upcase!
```

- Dot notation (`object.method`) makes the receiver obvious.
- Bang methods such as `upcase!` mutate the receiver; their non-bang counterparts return a new object.
- Predicate methods end with `?` (`empty?`, `include?`) and return true/false.

### Inspecting the current object

Use `self` whenever you need to check or pass the current receiver:

```ruby-exec
def log_self
  puts "Currently running inside #{self.class}: #{self.inspect}"
end

log_self  # top-level => main
```

Later chapters dive deeper into defining your own methods, but for now remember:

1. Every method belongs to a receiver.
2. Leaving off the receiver means "call this on `self`."
3. `self` changes based on where you are (top level, class body, instance method, etc.).

### Practice checklist

- [ ] Print `self` at the top level, inside a class body, and inside an instance method to watch it change.
- [ ] Rewrite a few explicit calls (e.g., `self.helper_method`) to implicit ones and confirm they still work.
- [ ] Experiment with predicate (`?`) and bang (`!`) method variants to see how they signal intent.
- [ ] Build a quick script that defines a helper method, calls it with and without an explicit receiver, and logs `self` along the way.

Next: apply these ideas in Flow Control & Collections, where you'll combine methods with loops and conditionals.

#### Practice 1 - Watching self in different contexts

**Goal:** Print `self` at the top level, inside a class body, and inside an instance method.

#> ruby :practice

# TODO: Print self at the top level, inside a class body, and inside
# an instance method, labelling each line so you can see the context.

```solution
puts "top level: #{self.inspect}"

class DemoSelf
  puts "class body: #{self.inspect}"

  def who_am_i
    puts "instance method: #{self.inspect}"
  end
end

DemoSelf.new.who_am_i
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('top level') } && lines.any? { |l| l.downcase.include?('class body') } && lines.any? { |l| l.downcase.include?('instance method') }
```

#!


#### Practice 2 - Explicit vs implicit receivers

**Goal:** Rewrite explicit receiver calls to use implicit receivers and confirm they still work.

#> ruby :practice

# TODO: Define a helper method and call it once with an explicit
# receiver (self.helper) and once without, printing labelled output
# for both calls.

```solution
def helper
  "helper called"
end

puts "explicit: #{self.helper}"
puts "implicit: #{helper}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('explicit') } && lines.any? { |l| l.downcase.include?('implicit') }
```

#!


#### Practice 3 - Predicate and bang methods

**Goal:** Experiment with predicate (`?`) and bang (`!`) method variants.

#> ruby :practice

# TODO: Use at least one predicate method and one bang method, and
# print before/after states to show how they differ.

```solution
name = "ruby"

puts "empty? before: #{name.empty?}"

puts "before upcase!: #{name}"
name.upcase!
puts "after upcase!: #{name}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('empty?') } && lines.any? { |l| l.include?('upcase!') }
```

#!


#### Practice 4 - Logging self through helper calls

**Goal:** Define a helper method, call it with and without an explicit receiver, and log `self` along the way.

#> ruby :practice

# TODO: Build a short script that defines a helper method and logs
# self inside it, then call the helper with both explicit and
# implicit receivers, printing labelled lines.

```solution
def helper_with_self(label)
  puts "#{label}: helper called, self is #{self.inspect}"
end

helper_with_self("implicit")
self.helper_with_self("explicit")
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('helper called') } && lines.any? { |l| l.downcase.include?('self is') }
```

#!

