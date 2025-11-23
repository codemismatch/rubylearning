---
layout: tutorial
title: "Chapter 24 &ndash; Writing Our Own Class"
permalink: /tutorials/writing-our-own-class/
difficulty: beginner
summary: Learn how classes describe objects, wire up instance variables and methods, and inspect the abilities Ruby gives every object.
previous_tutorial:
  title: "Chapter 23: Ruby Regular Expressions"
  url: /tutorials/ruby-regular-expressions/
next_tutorial:
  title: "Chapter 25: Ruby `method_missing`"
  url: /tutorials/ruby-method-missing/
related_tutorials:
  - title: "Ruby Symbols"
    url: /tutorials/ruby-symbols/
  - title: "Ruby Hashes"
    url: /tutorials/ruby-hashes/
---

> Adapted from Satish Talim's "Writing our own Class" lesson.

Procedural code focuses on steps. Object-oriented Ruby focuses on **objects**--small agents that know things (state) and do things (behavior). A **class** is a blueprint for those objects: it defines the instance variables an object carries and the methods it can respond to.

### Objects know things and do things

- What an object **knows** -> instance variables (state). Each object can hold different values.
- What an object **does** -> methods. Methods expose behavior to the rest of the program.

A class combines both. Each class is itself an instance of Ruby's `Class`, and calling `ClassName.new` allocates memory then calls the instance's `initialize` method. Construction (`new`) and initialization (`initialize`) are separate steps you can override independently.

### First class: `Dog`

```ruby-exec
# p029dog.rb
class Dog
  def initialize(breed, name)
    @breed = breed      # instance variables
    @name = name
  end

  def bark
    puts "Ruff! Ruff!"
  end

  def display
    puts "I am of #{@breed} breed and my name is #{@name}"
  end
end

d = Dog.new("Labrador", "Benzy")
puts "The id of d is #{d.object_id}."

if d.respond_to?(:talk)
  d.talk
else
  puts "Sorry, d doesn't understand the 'talk' message."
end

d.bark
d.display
```

Key takeaways:

- Instance variables start with `@` and are private to the object.
- Methods like `bark` and `display` form the public API.
- `object_id` shows the unique identifier Ruby assigns each object.
- `respond_to?` lets you ask whether an object understands a message before sending it--handy for duck typing.

Multiple variables can reference the same object, and setting a variable to `nil` simply drops that reference. When no references remain, Ruby's garbage collector reclaims the object.

### Introspection helpers

Ruby ships lots of methods on every object. Try `d.methods.sort` (commented out above) to see them. A few particularly useful ones:

- `object_id` - unique ID for the object.
- `respond_to?` - whether a method is defined.
- `class` - the object's class name.
- `instance_of?` - whether the object is an instance of a specific class (e.g., `num.instance_of?(Integer)`).

### Practice checklist

- [ ] Extend `Dog` with a `talk` method and watch `respond_to?` flip from false to true.
- [ ] Add reader/writer methods (or `attr_accessor`) for the instance variables so callers can rename dogs.
- [ ] Create two references to the same `Dog`, mutate via one reference, and verify the other sees the change.
- [ ] Print `Dog.new("Alsatian", "Lassie").class` and `object_id` to reinforce how Ruby manages objects.

Next: proceed to Flow Control & Collections to put your new objects to work inside loops and iterators.

#### Practice 1 - Extending Dog with #talk

**Goal:** Extend `Dog` with a `talk` method and watch `respond_to?` change.

#> ruby :practice

# TODO: Show a Dog class gaining a talk method and demonstrate
# respond_to? :talk returning true.

```solution
puts "class Dog"
puts "  def talk"
puts "    'woof'"
puts "  end"
puts "end"
puts "Dog.new.respond_to?(:talk)"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('talk') } && lines.any? { |l| l.include?('respond_to?') }
```

#!


#### Practice 2 - Reader/writer methods

**Goal:** Add reader/writer methods (or `attr_accessor`) for instance variables so callers can rename dogs.

#> ruby :practice

# TODO: Sketch a Dog class that uses attr_accessor for name and shows
# renaming a dog.

```solution
puts "class Dog"
puts "  attr_accessor :name"
puts "end"
puts "dog = Dog.new"
puts "dog.name = 'Lassie'"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('attr_accessor :name') }
```

#!


#### Practice 3 - Shared references to the same object

**Goal:** Create two references to the same `Dog`, mutate via one, and verify the other sees the change.

#> ruby :practice

# TODO: Print a short example where two variables point at the same
# Dog instance and a change via one is visible via the other.

```solution
puts "dog1 = Dog.new"
puts "dog2 = dog1"
puts "dog1.object_id == dog2.object_id # same object"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('same object') }
```

#!


#### Practice 4 - Class and object_id

**Goal:** Print `Dog.new(\"Alsatian\", \"Lassie\").class` and `object_id`.

#> ruby :practice

# TODO: Show the class and object_id for a freshly instantiated Dog.

```solution
puts "dog = Dog.new('Alsatian', 'Lassie')"
puts "dog.class"
puts "dog.object_id"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('object_id') }
```

#!

