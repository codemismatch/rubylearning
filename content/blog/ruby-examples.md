---
title: Ruby Practice Examples
layout: post
date: 2023-01-02
permalink: /blog/ruby-examples/
tags:
  - examples
  - syntax
  - basics
  - fundamentals
  - ruby
related_tutorials:
  - title: "Chapter 2: Flow control & collections"
    url: "/courses/ruby-basics/flow-control-collections/"
  - title: "Chapter 3: Methods & blocks"
    url: "/courses/ruby-basics/methods-and-blocks/"

---
# Practise alongside the Ruby tutorials

The dedicated Ruby tutorials page now houses the full learning path. Continue with [Chapter&nbsp;2](/courses/ruby-basics/#chapter-2) for flow control and collections or [Chapter&nbsp;3](/courses/ruby-basics/#chapter-3) for methods and blocks.

If you&rsquo;d like a quick refresher before diving back in, paste these examples into IRB and modify them after working through the practice checklists.

```ruby
# A simple Ruby class
class Person
  attr_accessor :name, :age
  
  def initialize(name, age)
    @name = name
    @age = age
  end
  
  def greet
    "Hello, my name is #{@name} and I am #{@age} years old."
  end
end

# Create a new person
person = Person.new("Alice", 30)
puts person.greet
```

## Interactive Example

You can also run this code:

```ruby-exec
class Calculator
  def add(a, b)
    a + b
  end
  
  def subtract(a, b)
    a - b
  end
end

calc = Calculator.new
puts "10 + 5 = #{calc.add(10, 5)}"
puts "10 - 5 = #{calc.subtract(10, 5)}"
```

Need more structured guidance? Head back to the [tutorials overview](/courses/ruby-basics/) for the full chapter list, or visit the [resources page](/pages/resources/) to find supporting courses, videos, and reference material.
