---
layout: tutorial
title: Chapter 4 &ndash; Classes & objects
permalink: /courses/ruby-basics/classes-and-objects/
difficulty: intermediate
summary: Model real-world concepts with Ruby classes, attribute readers, and collaborating objects.
previous_tutorial:
  title: "Chapter 3: Methods & blocks"
  url: /courses/ruby-basics/methods-and-blocks/
next_tutorial:
  title: "Chapter 5: Modules & mixins"
  url: /courses/ruby-basics/modules-and-mixins/
related_tutorials:
  - title: "Modules & mixins"
    url: /courses/ruby-basics/modules-and-mixins/
  - title: "Why Ruby's RubyLearning approach still works"
    url: /blog/ruby-learning-playbook/
date: 2025-10-31
---

> Revived from RubyLearning's tutorials by Satish Talim, with updates for modern Ruby development.

Ruby classes describe how objects behave. Lean on initializer methods, attribute readers, and instance methods to encapsulate state.

### Writing Our Own Class in Ruby {#writing-class}

So far, the procedural style of programming was used to write our programs. Programming in the object-oriented style allows classes and objects to be the center of the design:

```ruby-exec
class Person
  def initialize(name, age)
    @name = name
    @age = age
  end

  def introduce
    puts "Hi, I'm #{@name} and I'm #{@age} years old."
  end

  def have_birthday
    @age += 1
    puts "Happy birthday! Now I'm #{@age}."
  end
end

# Creating objects (instances) of the Person class
person1 = Person.new("Alice", 25)
person1.introduce
person1.have_birthday
```

### Defining classes {#classes}

```ruby-exec
class Course
  attr_reader :title, :chapters

  def initialize(title)
    @title = title
    @chapters = []
  end

  def add_chapter(name)
    chapters << name
  end

  def describe
    "#{title} covers: #{chapters.join(', ')}"
  end
end

ruby_course = Course.new("Ruby Essentials")
ruby_course.add_chapter("Meet Ruby")
ruby_course.add_chapter("Flow control")
puts ruby_course.describe
```

### Instance Variables and Methods {#instance-vars}

```ruby-exec
class BankAccount
  def initialize(account_holder, initial_balance = 0)
    @account_holder = account_holder
    @balance = initial_balance
  end

  def deposit(amount)
    @balance += amount if amount > 0
    puts "Deposited $#{amount}. New balance: $#{@balance}"
  end

  def withdraw(amount)
    if amount > 0 &&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&& @balance >= amount
      @balance -= amount
      puts "Withdrew $#{amount}. New balance: $#{@balance}"
    else
      puts "Insufficient funds or invalid amount"
    end
  end

  def balance
    @balance
  end
end

account = BankAccount.new("John Doe", 100)
account.deposit(50)
account.withdraw(25)
puts "Final balance: $#{account.balance}"
```

### Attribute Accessors {#attribute-accessors}

```ruby-exec
class Book
  # attr_reader :title, :author - creates getter methods only
  # attr_writer :title, :author - creates setter methods only
  # attr_accessor :title, :author - creates both getter and setter methods

  attr_accessor :title, :author
  attr_reader :pages

  def initialize(title, author, pages)
    @title = title
    @author = author
    @pages = pages
  end
end

book = Book.new("The Ruby Programming Language", "Matz", 400)
puts book.title      # Getter method
book.title = "New Title"  # Setter method
puts book.title      # Getter method
# book.pages = 500   # This would cause an error since we only have a reader for pages
puts book.pages      # 400
```

### Inheritance {#inheritance}

Inheritance is a relation between two classes. We know that all cats are mammals, and all mammals are animals. The benefit of inheritance is that the derived classes are a subset of the base class:

```ruby-exec
class Animal
  def initialize(name)
    @name = name
  end

  def eat
    puts "#{@name} is eating."
  end

  def sleep
    puts "#{@name} is sleeping."
  end
end

class Dog < Animal
  def bark
    puts "#{@name} is barking: Woof!"
  end

  def sleep  # Overriding parent method
    super  # Call parent implementation
    puts "#{@name} is sleeping soundly."
  end
end

class Cat < Animal
  def meow
    puts "#{@name} is meowing: Meow!"
  end
end

dog = Dog.new("Buddy")
dog.eat      # Inherited method
dog.bark     # Dog's own method
dog.sleep    # Overridden method

cat = Cat.new("Whiskers")
cat.eat      # Inherited method
cat.meow     # Cat's own method
```

### Method Overriding {#method-overriding}

Method overriding, in object oriented programming, is a language feature that allows a subclass to provide a specific implementation of a method that is already provided by one of its superclasses:

```ruby-exec
class Shape
  def area
    "Area of shape"
  end
end

class Rectangle < Shape
  def initialize(width, height)
    @width = width
    @height = height
  end

  def area  # Overriding the parent's area method
    @width * @height
  end
end

class Circle < Shape
  def initialize(radius)
    @radius = radius
  end

  def area  # Overriding the parent's area method
    3.14159 * @radius * @radius
  end
end

rect = Rectangle.new(5, 3)
puts "Rectangle area: #{rect.area}"

circle = Circle.new(4)
puts "Circle area: #{circle.area}"
```

### Access Control {#access-control}

The only easy way to change an object's state in Ruby is by calling one of its methods. Control access to the methods:

```ruby-exec
class BankAccount
  def initialize(account_number, balance = 0)
    @account_number = account_number
    @balance = balance
  end

  def check_balance(password)
    if password == "secret123"
      show_balance
    else
      puts "Access denied"
    end
  end

  def deposit(amount)
    @balance += amount if valid_amount?(amount)
  end

  private  # Methods after this are private by default

  def show_balance
    puts "Balance: $#{@balance}"
  end

  def valid_amount?(amount)
    amount > 0
  end
end

account = BankAccount.new("12345", 1000)
account.deposit(500)
# account.show_balance  # This would cause an error since show_balance is private
account.check_balance("secret123")  # This works as check_balance calls show_balance internally
```

### Ruby Open Classes {#open-classes}

In Ruby, classes are never closed: you can always add methods to an existing class. This applies to the classes you write as well as the standard library classes:

```ruby-exec
# Adding a method to the existing String class
class String
  def palindrome?
    self.downcase == self.downcase.reverse
  end

  def word_count
    self.split.length
  end
end

puts "racecar".palindrome? # true
puts "hello world".word_count # 2

# Adding a method to the existing Integer class
class Integer
  def factorial
    return 1 if self <= 1
    (1..self).reduce(:*)
  end
end

puts 5.factorial # 120
```

### Duck Typing {#duck-typing}

In Ruby, we rely less on the type (or class) of an object and more on its capabilities. Duck Typing means an object type is defined by what it does, not what it is:

```ruby-exec
class Duck
  def speak
    puts "Quack!"
  end

  def swim
    puts "Paddling through the water"
  end
end

class Dog
  def speak
    puts "Woof!"
  end

  def swim
    puts "Doggy paddle"
  end
end

make_it_speak_and_swim = ->(animal) do
  animal.speak
  animal.swim
end

duck = Duck.new
dog = Dog.new

make_it_speak_and_swim.call(duck) # Works because Duck has speak and swim methods
make_it_speak_and_swim.call(dog) # Works because Dog has speak and swim methods
```

### Practice checklist

- Create a class with instance variables and methods
- Practice inheritance by creating parent and child classes
- Implement method overriding
- Use attribute accessors appropriately
- Try extending existing Ruby classes with new methods
- Experiment with access control using private/protected methods

#### Practice 1 - Defining a simple class

**Goal:** Create a class with instance variables and methods.

#> ruby :practice

# TODO: Define a Person class with instance variables such as name
# and age, plus a method that prints a friendly description.
# Hint:
#   - Store values in @name, @age.
#   - Add an instance method like #describe that prints them.
#
# Define your class in this block; the test harness will try to
# instantiate sandbox::Person.

```solution
class Person
  def initialize(name, age)
    @name = name
    @age = age
  end

  def describe
    puts "#{@name} is #{@age} years old"
  end
end

person = Person.new("Alex", 30)
person.describe
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('Alex') } && lines.any? { |l| l.include?('30') }
```

#!


#### Practice 2 - Practising inheritance

**Goal:** Create a parent and child class that share behaviour via inheritance.

#> ruby :practice

# TODO: Define a Vehicle class with a start method, then create a
# Car subclass that inherits from Vehicle and adds its own behaviour.
# Hint:
#   - Use < to declare inheritance: class Car < Vehicle
#   - Instantiate both and call their methods.

```solution
class Vehicle
  def initialize(name)
    @name = name
  end

  def start
    puts "#{@name} is starting"
  end
end

class Car < Vehicle
  def honk
    puts "#{@name} says: Beep!"
  end
end

vehicle = Vehicle.new("RubyMobile")
vehicle.start

car = Car.new("RailsRunner")
car.start
car.honk
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('RubyMobile') } && lines.any? { |l| l.include?('RailsRunner') }
```

#!


#### Practice 3 - Implementing method overriding

**Goal:** Override a method in a subclass.

#> ruby :practice

# TODO: Create a base class with a method, then a subclass that
# overrides that method to specialise the behaviour.
# Hint:
#   - Define an Animal class with a #sleep method.
#   - Define a Cat subclass that overrides #sleep.

```solution
class Animal
  def initialize(name)
    @name = name
  end

  def sleep
    puts "#{@name} is sleeping."
  end
end

class Cat < Animal
  def sleep
    puts "#{@name} is sleeping on the keyboard."
  end
end

cat = Cat.new("Misty")
cat.sleep
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('misty is sleeping') }
```

#!


#### Practice 4 - Using attribute accessors

**Goal:** Use attribute accessors to create getters and setters.

#> ruby :practice

# TODO: Define a Book class that uses attr_accessor and attr_reader,
# then demonstrate reading and writing attributes.
# Hint:
#   - Use attr_accessor for mutable fields, attr_reader for read-only.

```solution
class Book
  attr_accessor :title, :author
  attr_reader :pages

  def initialize(title, author, pages = 0)
    @title = title
    @author = author
    @pages = pages
  end
end

book = Book.new("Ruby 101", "Satish", 200)
book.title = "Ruby 102"
puts "Title: #{book.title}"
puts "Pages: #{book.pages}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('Ruby 102') }
```

#!


#### Practice 5 - Extending existing classes

**Goal:** Extend an existing Ruby class with a new method.

#> ruby :practice

# TODO: Open an existing class (such as String) and add a small
# helper method, then call it.
# Hint:
#   - For example, define String#shout that returns the string in
#     uppercase with an exclamation mark.

```solution
class String
  def shout
    upcase + "!"
  end
end

puts "hello from ruby".shout
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('hello from ruby') }
```

#!


#### Practice 6 - Access control with private/protected

**Goal:** Experiment with private/protected methods and see how they affect access.

#> ruby :practice

# TODO: Define a class that has a public method using a private helper
# and experiment with calling the helper from outside the class.
# Hint:
#   - Use private to hide an implementation detail.

```solution
class Account
  def initialize(balance)
    @balance = balance
  end

  def print_balance
    puts "Balance: #{formatted_balance}"
  end

  private

  def formatted_balance
    "$#{@balance}"
  end
end

account = Account.new(100)
account.print_balance
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('balance:') }
```

#!


Continue to [Chapter 5: Modules & mixins](/courses/ruby-basics/modules-and-mixins/) to share behaviour across objects.
