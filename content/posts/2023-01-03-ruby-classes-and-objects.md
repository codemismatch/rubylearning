---
title: Understanding Ruby Classes and Objects
layout: post
date: 2023-01-03
description: Learn about object-oriented programming in Ruby through classes and objects
tags:
  - oop
  - classes
  - objects
  - object-oriented
difficulty: intermediate
related_tutorials:
  - title: "Ruby examples"
    url: "/posts/2023-01-02-ruby-examples/"

---
# Understanding Ruby Classes and Objects

Object-oriented programming is one of Ruby's core paradigms. Let's explore how classes and objects work in Ruby.

## What is a Class?

In Ruby, a class is a blueprint for creating objects. It defines the properties and behaviors that its instances (objects) will have.

Here's a simple class definition:

```ruby
class Book
  attr_accessor :title, :author, :pages
  
  def initialize(title, author, pages)
    @title = title
    @author = author
    @pages = pages
  end
  
  def to_s
    "#{@title} by #{@author} (#{@pages} pages)"
  end
  
  def read
    puts "You're reading #{@title}. Enjoy!"
  end
end
```

## Creating Objects

Once you have a class, you can create objects (instances of the class):

```ruby
# Create new Book objects
book1 = Book.new("The Ruby Programming Language", "Matz", 472)
book2 = Book.new("Eloquent Ruby", "Russ Olsen", 448)

# Access attributes
puts book1.title   # => "The Ruby Programming Language"
puts book2.author  # => "Russ Olsen"

# Call methods
puts book1         # => "The Ruby Programming Language by Matz (472 pages)"
book2.read         # => "You're reading Eloquent Ruby. Enjoy!"
```

## Instance Variables

Instance variables (prefixed with `@`) store object-specific data. Each object has its own set of instance variables.

## Instance Methods

Instance methods define behavior for individual objects:

```ruby
class Circle
  attr_accessor :radius
  
  def initialize(radius)
    @radius = radius
  end
  
  def area
    Math::PI * @radius ** 2
  end
  
  def circumference
    2 * Math::PI * @radius
  end
end

circle = Circle.new(5)
puts "Area: #{circle.area}"
puts "Circumference: #{circle.circumference}"
```

## Class Variables and Methods

Class variables (prefixed with `@@`) are shared across all instances of a class. Class methods are defined with `self.`:

```ruby
class Counter
  @@count = 0
  
  def initialize
    @@count += 1
  end
  
  def self.count
    @@count
  end
end

Counter.new
Counter.new
Counter.new

puts Counter.count  # => 3
```

## Try It Yourself

```ruby
class Animal
  attr_accessor :name, :species
  
  def initialize(name, species)
    @name = name
    @species = species
  end
  
  def speak
    puts "#{@name} makes a sound"
  end
end

class Dog < Animal
  def initialize(name)
    super(name, "Canine")
  end
  
  def speak
    puts "#{@name} says: Woof!"
  end
end

class Cat < Animal
  def initialize(name)
    super(name, "Feline")
  end
  
  def speak
    puts "#{@name} says: Meow!"
  end
end

# Create some animals
dog = Dog.new("Rex")
cat = Cat.new("Whiskers")

# Call methods
dog.speak
cat.speak

puts "#{dog.name} is a #{dog.species}"
puts "#{cat.name} is a #{cat.species}"
```

This example demonstrates inheritance in Ruby, where `Dog` and `Cat` classes inherit from the `Animal` class but override specific behaviors.
