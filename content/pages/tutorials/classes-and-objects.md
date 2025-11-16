---
layout: tutorial
title: Chapter 4 &ndash; Classes & objects
permalink: /tutorials/classes-and-objects/
difficulty: intermediate
summary: Model real-world concepts with Ruby classes, attribute readers, and collaborating objects.
previous_tutorial:
  title: "Chapter 3: Methods & blocks"
  url: /tutorials/methods-and-blocks/
next_tutorial:
  title: "Chapter 5: Modules & mixins"
  url: /tutorials/modules-and-mixins/
related_tutorials:
  - title: "Modules & mixins"
    url: /tutorials/modules-and-mixins/
  - title: "Why Ruby's RubyLearning approach still works"
    url: /blog/ruby-learning-playbook/
---

> Revived from RubyLearning's tutorials by Satish Talim, with updates for modern Ruby development.

Ruby classes describe how objects behave. Lean on initializer methods, attribute readers, and instance methods to encapsulate state.

### Writing Our Own Class in Ruby {#writing-class}

So far, the procedural style of programming was used to write our programs. Programming in the object-oriented style allows classes and objects to be the center of the design:

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
class Person
  def initialize(name, age)
    @name = name
    @age = age
  end

  def introduce
    puts &quot;Hi, I&#39;m #{@name} and I&#39;m #{@age} years old.&quot;
  end

  def have_birthday
    @age += 1
    puts &quot;Happy birthday! Now I&#39;m #{@age}.&quot;
  end
end

# Creating objects (instances) of the Person class
person1 = Person.new(&quot;Alice&quot;, 25)
person1.introduce
person1.have_birthday
</code></pre>

### Defining classes {#classes}

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
class Course
  attr_reader :title, :chapters

  def initialize(title)
    @title = title
    @chapters = []
  end

  def add_chapter(name)
    chapters &lt;&lt; name
  end

  def describe
    &quot;#{title} covers: #{chapters.join(&#39;, &#39;)}&quot;
  end
end

ruby_course = Course.new(&quot;Ruby Essentials&quot;)
ruby_course.add_chapter(&quot;Meet Ruby&quot;)
ruby_course.add_chapter(&quot;Flow control&quot;)
puts ruby_course.describe
</code></pre>

### Instance Variables and Methods {#instance-vars}

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
class BankAccount
  def initialize(account_holder, initial_balance = 0)
    @account_holder = account_holder
    @balance = initial_balance
  end

  def deposit(amount)
    @balance += amount if amount &gt; 0
    puts &quot;Deposited $#{amount}. New balance: $#{@balance}&quot;
  end

  def withdraw(amount)
    if amount &gt; 0 &amp;&amp; @balance &gt;= amount
      @balance -= amount
      puts &quot;Withdrew $#{amount}. New balance: $#{@balance}&quot;
    else
      puts &quot;Insufficient funds or invalid amount&quot;
    end
  end

  def balance
    @balance
  end
end

account = BankAccount.new(&quot;John Doe&quot;, 100)
account.deposit(50)
account.withdraw(25)
puts &quot;Final balance: $#{account.balance}&quot;
</code></pre>

### Attribute Accessors {#attribute-accessors}

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
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

book = Book.new(&quot;The Ruby Programming Language&quot;, &quot;Matz&quot;, 400)
puts book.title      # Getter method
book.title = &quot;New Title&quot;  # Setter method
puts book.title      # Getter method
# book.pages = 500   # This would cause an error since we only have a reader for pages
puts book.pages      # 400
</code></pre>

### Inheritance {#inheritance}

Inheritance is a relation between two classes. We know that all cats are mammals, and all mammals are animals. The benefit of inheritance is that the derived classes are a subset of the base class:

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
class Animal
  def initialize(name)
    @name = name
  end

  def eat
    puts &quot;#{@name} is eating.&quot;
  end

  def sleep
    puts &quot;#{@name} is sleeping.&quot;
  end
end

class Dog &lt; Animal
  def bark
    puts &quot;#{@name} is barking: Woof!&quot;
  end

  def sleep  # Overriding parent method
    super  # Call parent implementation
    puts &quot;#{@name} is sleeping soundly.&quot;
  end
end

class Cat &lt; Animal
  def meow
    puts &quot;#{@name} is meowing: Meow!&quot;
  end
end

dog = Dog.new(&quot;Buddy&quot;)
dog.eat      # Inherited method
dog.bark     # Dog&#39;s own method
dog.sleep    # Overridden method

cat = Cat.new(&quot;Whiskers&quot;)
cat.eat      # Inherited method
cat.meow     # Cat&#39;s own method
</code></pre>

### Method Overriding {#method-overriding}

Method overriding, in object oriented programming, is a language feature that allows a subclass to provide a specific implementation of a method that is already provided by one of its superclasses:

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
class Shape
  def area
    &quot;Area of shape&quot;
  end
end

class Rectangle &lt; Shape
  def initialize(width, height)
    @width = width
    @height = height
  end

  def area  # Overriding the parent&#39;s area method
    @width * @height
  end
end

class Circle &lt; Shape
  def initialize(radius)
    @radius = radius
  end

  def area  # Overriding the parent&#39;s area method
    3.14159 * @radius * @radius
  end
end

rect = Rectangle.new(5, 3)
puts &quot;Rectangle area: #{rect.area}&quot;

circle = Circle.new(4)
puts &quot;Circle area: #{circle.area}&quot;
</code></pre>

### Access Control {#access-control}

The only easy way to change an object's state in Ruby is by calling one of its methods. Control access to the methods:

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
class BankAccount
  def initialize(account_number, balance = 0)
    @account_number = account_number
    @balance = balance
  end

  def check_balance(password)
    if password == &quot;secret123&quot;
      show_balance
    else
      puts &quot;Access denied&quot;
    end
  end

  def deposit(amount)
    @balance += amount if valid_amount?(amount)
  end

  private  # Methods after this are private by default

  def show_balance
    puts &quot;Balance: $#{@balance}&quot;
  end

  def valid_amount?(amount)
    amount &gt; 0
  end
end

account = BankAccount.new(&quot;12345&quot;, 1000)
account.deposit(500)
# account.show_balance  # This would cause an error since show_balance is private
account.check_balance(&quot;secret123&quot;)  # This works as check_balance calls show_balance internally
</code></pre>

### Ruby Open Classes {#open-classes}

In Ruby, classes are never closed: you can always add methods to an existing class. This applies to the classes you write as well as the standard library classes:

<pre class="language-ruby"><code class="language-ruby">
# Adding a method to the existing String class
class String
  def palindrome?
    self.downcase == self.downcase.reverse
  end

  def word_count
    self.split.length
  end
end

puts &quot;racecar&quot;.palindrome? # true
puts &quot;hello world&quot;.word_count # 2

# Adding a method to the existing Integer class
class Integer
  def factorial
    return 1 if self &lt;= 1
    (1..self).reduce(:*)
  end
end

puts 5.factorial # 120
</code></pre>

### Duck Typing {#duck-typing}

In Ruby, we rely less on the type (or class) of an object and more on its capabilities. Duck Typing means an object type is defined by what it does, not what it is:

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
class Duck
  def speak
    puts &quot;Quack!&quot;
  end

  def swim
    puts &quot;Paddling through the water&quot;
  end
end

class Dog
  def speak
    puts &quot;Woof!&quot;
  end

  def swim
    puts &quot;Doggy paddle&quot;
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
</code></pre>

### Practice checklist

- Create a class with instance variables and methods
- Practice inheritance by creating parent and child classes
- Implement method overriding
- Use attribute accessors appropriately
- Try extending existing Ruby classes with new methods
- Experiment with access control using private/protected methods

#### Practice 1 - Defining a simple class

<p><strong>Goal:</strong> Create a class with instance variables and methods.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/classes-and-objects"
     data-practice-index="0"
     data-test="require 'test/unit/assertions'; extend Test::Unit::Assertions; sandbox.const_defined?(:Person); person_class = sandbox.const_get(:Person); p = person_class.new('Alex', 30); out = output.string; assert out.lines.any? { |l| l.include?('Alex') }; true"><code class="language-ruby">
# TODO: Define a Person class with instance variables such as name
# and age, plus a method that prints a friendly description.
# Hint:
#   - Store values in @name, @age.
#   - Add an instance method like #describe that prints them.
#
# Define your class in this block; the test harness will try to
# instantiate sandbox::Person.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/classes-and-objects"
     data-practice-index="0"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/classes-and-objects:0">
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
</script>

#### Practice 2 - Practising inheritance

<p><strong>Goal:</strong> Create a parent and child class that share behaviour via inheritance.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/classes-and-objects"
     data-practice-index="1"
     data-test="require 'test/unit/assertions'; extend Test::Unit::Assertions; sandbox.const_defined?(:Vehicle) && sandbox.const_defined?(:Car); vehicle = sandbox.const_get(:Vehicle).new('RubyMobile'); car = sandbox.const_get(:Car).new('RailsRunner'); out = output.string; assert out.lines.any? { |l| l.include?('RubyMobile') }; assert out.lines.any? { |l| l.include?('RailsRunner') }; true"><code class="language-ruby">
# TODO: Define a Vehicle class with a start method, then create a
# Car subclass that inherits from Vehicle and adds its own behaviour.
# Hint:
#   - Use &lt; to declare inheritance: class Car &lt; Vehicle
#   - Instantiate both and call their methods.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/classes-and-objects"
     data-practice-index="1"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/classes-and-objects:1">
class Vehicle
  def initialize(name)
    @name = name
  end

  def start
    puts "#{@name} is starting"
  end
end

class Car &lt; Vehicle
  def honk
    puts "#{@name} says: Beep!"
  end
end

vehicle = Vehicle.new("RubyMobile")
vehicle.start

car = Car.new("RailsRunner")
car.start
car.honk
</script>

#### Practice 3 - Implementing method overriding

<p><strong>Goal:</strong> Override a method in a subclass.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/classes-and-objects"
     data-practice-index="2"
     data-test="require 'test/unit/assertions'; extend Test::Unit::Assertions; sandbox.const_defined?(:Animal) && sandbox.const_defined?(:Cat); cat = sandbox.const_get(:Cat).new('Misty'); out = output.string; assert out.lines.any? { |l| l.downcase.include?('misty is sleeping') }; true"><code class="language-ruby">
# TODO: Create a base class with a method, then a subclass that
# overrides that method to specialise the behaviour.
# Hint:
#   - Define an Animal class with a #sleep method.
#   - Define a Cat subclass that overrides #sleep.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/classes-and-objects"
     data-practice-index="2"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/classes-and-objects:2">
class Animal
  def initialize(name)
    @name = name
  end

  def sleep
    puts "#{@name} is sleeping."
  end
end

class Cat &lt; Animal
  def sleep
    puts "#{@name} is sleeping on the keyboard."
  end
end

cat = Cat.new("Misty")
cat.sleep
</script>

#### Practice 4 - Using attribute accessors

<p><strong>Goal:</strong> Use attribute accessors to create getters and setters.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/classes-and-objects"
     data-practice-index="3"
     data-test="require 'test/unit/assertions'; extend Test::Unit::Assertions; sandbox.const_defined?(:Book); book = sandbox.const_get(:Book).new('Ruby 101', 'Satish'); book.title = 'Ruby 102'; out = output.string; assert out.lines.any? { |l| l.include?('Ruby 102') }; true"><code class="language-ruby">
# TODO: Define a Book class that uses attr_accessor and attr_reader,
# then demonstrate reading and writing attributes.
# Hint:
#   - Use attr_accessor for mutable fields, attr_reader for read-only.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/classes-and-objects"
     data-practice-index="3"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/classes-and-objects:3">
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
</script>

#### Practice 5 - Extending existing classes

<p><strong>Goal:</strong> Extend an existing Ruby class with a new method.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/classes-and-objects"
     data-practice-index="4"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('hello from ruby') }"><code class="language-ruby">
# TODO: Open an existing class (such as String) and add a small
# helper method, then call it.
# Hint:
#   - For example, define String#shout that returns the string in
#     uppercase with an exclamation mark.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/classes-and-objects"
     data-practice-index="4"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/classes-and-objects:4">
class String
  def shout
    upcase + "!"
  end
end

puts "hello from ruby".shout
</script>

#### Practice 6 - Access control with private/protected

<p><strong>Goal:</strong> Experiment with private/protected methods and see how they affect access.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/classes-and-objects"
     data-practice-index="5"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('balance:') }"><code class="language-ruby">
# TODO: Define a class that has a public method using a private helper
# and experiment with calling the helper from outside the class.
# Hint:
#   - Use private to hide an implementation detail.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/classes-and-objects"
     data-practice-index="5"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/classes-and-objects:5">
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
</script>

Continue to [Chapter 5: Modules & mixins](/tutorials/modules-and-mixins/) to share behaviour across objects.
