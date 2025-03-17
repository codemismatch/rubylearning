---
title: Ruby Code Examples
layout: post
date: 2023-01-02
tags: [ruby, code]
---

# Ruby Code Examples

Here are some Ruby code examples that you can use:

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
