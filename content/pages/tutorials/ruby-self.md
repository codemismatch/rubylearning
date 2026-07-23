---
layout: tutorial
title: "Chapter 41 &ndash; Understanding `self`"
permalink: /courses/ruby-basics/ruby-self/
difficulty: intermediate
summary: "`self` always points to the current object--learn how it shifts between top-level code, class bodies, and methods."
previous_tutorial:
  title: "Chapter 40: Modules & Mixins"
  url: /courses/ruby-basics/modules-and-mixins/
next_tutorial:
  title: "Chapter 42: Ruby Constants"
  url: /courses/ruby-basics/ruby-constants/
related_tutorials:
  - title: "Writing Our Own Class"
    url: /courses/ruby-basics/writing-our-own-class/
  - title: "Ruby Open Classes"
    url: /courses/ruby-basics/ruby-open-classes/
---

> Adapted from Satish Talim's "Ruby self" lesson.

`self` always references "the current object," but that object changes depending on where you are in the code.

### Top-level `self`

At the top level of a file:

```ruby-exec
puts self        #=> main
puts self.class  #=> Object
```

`main` is an instance of `Object` that Ruby uses to evaluate top-level code.

### Inside class definitions

Within the class body (outside instance methods), `self` is the class object:

```ruby-exec
class Person
  puts self        #=> Person
  def instance_method
    puts self.inspect
  end

  def self.class_method
    puts self      #=> Person
  end
end

Person.new.instance_method #=> #<Person:...>
Person.class_method        #=> Person
```

- Instance methods: `self` is the receiver (the instance).
- Class methods: `self` is the class itself.

### Practice checklist

- [ ] Print `self` in top-level code, inside a class body, inside an instance method, and inside a class method.
- [ ] Define a module and print `self` within `module` scope to see how it becomes the module object.
- [ ] Use `instance_eval` or `class << self` to explore how `self` shifts in singleton/class contexts.
- [ ] Combine with `method_missing` or `respond_to?` to see how `self` affects dynamic behavior.

Next: keep iterating through Flow Control & Collections, now confident about who `self` is in every context.

#### Practice 1 - self in common contexts

**Goal:** Print `self` in top-level code, inside a class body, inside an instance method, and inside a class method.

#> ruby :practice

# TODO: Print labelled lines for self in the four contexts described
# above so you can compare them.

```solution
puts "top-level: #{self.inspect}"

class SelfDemo
  puts "class-body: #{self.inspect}"

  def instance_example
    puts "instance-method: #{self.inspect}"
  end

  def self.class_example
    puts "class-method: #{self.inspect}"
  end
end

SelfDemo.new.instance_example
SelfDemo.class_example
```

```test
out = output.string; lines = out.lines.map(&:strip); %w[top-level class-body instance-method class-method].all? { |label| lines.any? { |l| l.downcase.include?(label) } }
```

#!


#### Practice 2 - self in module scope

**Goal:** Define a module and print `self` within module scope.

#> ruby :practice

# TODO: Sketch a module that prints self from within its body to show
# that self is the module object there.

```solution
module ModuleDemo
  puts "module scope: #{self.inspect}"
end
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('module scope') }
```

#!


#### Practice 3 - instance_eval and class << self

**Goal:** Use `instance_eval` or `class << self` to explore how `self` shifts in singleton/class contexts.

#> ruby :practice

# TODO: Print an example using instance_eval and class << self that
# shows self changing inside each context.

```solution
obj = Object.new
obj.instance_eval { puts "instance_eval self: #{self.inspect}" }

class SingletonDemo
  class << self
    puts "class << self: #{self.inspect}"
  end
end
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('instance_eval') } && lines.any? { |l| l.downcase.include?('class << self') }
```

#!


#### Practice 4 - self with dynamic behaviour

**Goal:** Combine `self` with `respond_to?` to see how `self` affects dynamic behavior.

#> ruby :practice

# TODO: Print a small dynamic call that uses respond_to? on self before
# sending a message.

```solution
class DynamicResponder
  def to_str
    "dynamic"
  end

  def check_to_str
    if self.respond_to?(:to_str)
      puts "self responds to to_str"
    else
      puts "self does NOT respond to to_str"
    end
  end
end

DynamicResponder.new.check_to_str
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('responds to to_str') }
```

#!
