---
layout: tutorial
title: Chapter 5 &ndash; Modules & mixins
permalink: /tutorials/modules-and-mixins/
difficulty: intermediate
summary: Share behaviour across objects with mixins and understand when to `include` versus `extend`.
previous_tutorial:
  title: "Chapter 4: Classes & objects"
  url: /tutorials/classes-and-objects/
next_tutorial:
  title: "Chapter 6: Files, gems & next steps"
  url: /tutorials/files-gems-next-steps/
related_tutorials:
  - title: "Files, gems & next steps"
    url: /tutorials/files-gems-next-steps/
  - title: "Ruby practice examples"
    url: /blog/ruby-examples/
---

> Revived from RubyLearning's tutorials by Satish Talim, with updates for modern Ruby development.

Modules group methods that multiple classes can reuse. Include them to mix behaviour into existing objects without changing inheritance.

### Ruby Modules and Mixins {#modules-mixins}

Ruby Modules are similar to classes in that they hold a collection of methods, constants, and other module and class definitions. Modules cannot be instantiated - you cannot create objects from a module:

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
module Greetings
  def hello
    puts &quot;Hello from module!&quot;
  end

  def goodbye
    puts &quot;Goodbye from module!&quot;
  end
end

class Person
  include Greetings
end

person = Person.new
person.hello # Calls the method from the included module
person.goodbye # Calls the method from the included module
</code></pre>

### Include vs Extend vs Prepend {#include-extend-prepend}

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
module ExampleModule
  def example_method
    puts &quot;Method from ExampleModule&quot;
  end
end

class ExampleClass
  # include - adds methods as instance methods
  include ExampleModule

  # extend - adds methods as class methods
  extend ExampleModule
end

obj = ExampleClass.new
obj.example_method # Works - instance method

ExampleClass.example_method  # Works - class method
</code></pre>

### Constants in Modules {#constants}

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
module MathConstants
  PI = 3.14159
  E = 2.71828
  GOLDEN_RATIO = 1.61803
end

puts MathConstants::PI
puts MathConstants::E
puts MathConstants::GOLDEN_RATIO

# Accessing constants from within classes
class Calculator
  def calculate_circumference(radius)
    2 * MathConstants::PI * radius
  end
end

calc = Calculator.new
puts calc.calculate_circumference(5)
</code></pre>

### Namespacing with Modules {#namespacing}

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
module Banking
  class Account
    def initialize(balance = 0)
      @balance = balance
    end

    def deposit(amount)
      @balance += amount
    end

    def balance
      @balance
    end
  end

  module Validators
    def self.valid_account_number?(number)
      number.length == 10 &amp;&amp; number.match?(/\d+/)
    end
  end
end

# Using namespaced classes
account = Banking::Account.new(100)
account.deposit(50)
puts account.balance

# Using namespaced methods
puts Banking::Validators.valid_account_number?(&quot;1234567890&quot;)  # true
puts Banking::Validators.valid_account_number?(&quot;12345&quot;)      # false
</code></pre>

### Understanding `self` {#self}

At every point when your program is running, there is one and only one `self` - the current or default object accessible to you in your program:

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
module Identity
  def who_am_i?
    # self refers to the instance that includes this module
    puts &quot;I am #{self}&quot;  # Fixed interpolation
    puts &quot;My class is #{self.class}&quot;  # Fixed interpolation
  end
end

class Student
  include Identity

  def initialize(name)
    @name = name
  end

  def show_self
    puts &quot;Inside instance method, self is: #{self}&quot;  # Fixed interpolation
    puts &quot;Inside instance method, self&#39;s class is: #{self.class}&quot;  # Fixed interpolation
  end

  def self.class_method_self
    puts &quot;Inside class method, self is: #{self}&quot;  # Fixed interpolation
  end
end

student = Student.new(&quot;Alice&quot;)
student.who_am_i?        # Shows the student object
student.show_self        # Shows the student object
Student.class_method_self  # Shows the Student class
</code></pre>

### Including Other Files in Ruby {#including-files}

When writing your first few Ruby programs, you tend to place all of your code in a single file. But as you grow as a Ruby programmer, your code gets split into multiple files. Ruby provides `require` and `load` to include other files:

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
# To include Ruby files, you would typically use:
# require &#39;./my_module&#39;  # Include once
# load &#39;./my_file.rb&#39;   # Include every time
# require_relative &#39;path/to/file&#39;  # Relative to current file

# For example, if you had a file called &#39;helpers.rb&#39;:
# require_relative &#39;helpers&#39;
</code></pre>

In practice, you would create separate files and reference them, but here's a demonstration of how it works conceptually.

### Ruby Method Missing {#method-missing}

When you send a message to an object, the object executes the first method it finds on its method lookup path with the same name as the message. If no method is found, Ruby calls the `method_missing` method:

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
class DynamicResponder
  def method_missing(method_name, *arguments, &amp;block)
    if method_name.to_s.start_with?(&#39;say_&#39;)
      message = method_name.to_s.delete_prefix(&#39;say_&#39;).tr(&#39;_&#39;, &#39; &#39;)
      puts &quot;Saying: #{message}&quot;  # Fixed interpolation
    else
      super  # Call the default behavior if method isn&#39;t handled
    end
  end
end

responder = DynamicResponder.new
responder.say_hello_world        # Outputs: &quot;Saying: hello world&quot;
responder.say_ruby_is_awesome    # Outputs: &quot;Saying: ruby is awesome&quot;
</code></pre>

### Ruby Syntactic Sugar {#syntactic-sugar}

Programmers use the term syntactic sugar to refer to special rules that let you write your code in a way that doesn't correspond to the language's formal grammar, but is easier to write and read:

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
# Assignment
a = 5  # Standard assignment
a = b = 10  # Multiple assignment

# Conditional assignment - only assigns if variable is nil
x = nil
x ||= 20
puts x  # 20

y = 5
y ||= 20
puts y  # 5 (not assigned because y was already set)

# Array and hash access
arr = [1, 2, 3]
puts arr[0]    # 1
arr[0] = 10    # Assignment equivalent to arr.[]=(0, 10)

hash = { a: 1, b: 2 }
puts hash[:a]  # 1
hash[:a] = 10  # Assignment equivalent to hash.[]=(:a, 10)
</code></pre>

### Mutable and Immutable Objects {#mutable-immutable}

Mutable objects are objects whose state can change. Immutable objects are objects whose state never changes after creation:

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
# Strings are mutable
str = &quot;Hello&quot;
puts &quot;Original: #{str}, object_id: #{str.object_id}&quot;  # Fixed interpolation
str &lt;&lt; &quot; World&quot;  # Modifies the original string
puts &quot;Modified: #{str}, object_id: #{str.object_id}&quot;  # Fixed interpolation

# Numbers are immutable
num = 5
original_id = num.object_id
num = num + 1
new_id = num.object_id
puts &quot;Original object_id: #{original_id}, New object_id: #{new_id}&quot;  # Different IDs - Fixed interpolation

# Arrays are mutable
arr = [1, 2, 3]
puts &quot;Original array: #{arr}, object_id: #{arr.object_id}&quot;  # Fixed interpolation
arr &lt;&lt; 4  # Modifies the original array
puts &quot;Modified array: #{arr}, object_id: #{arr.object_id}&quot;  # Same ID - Fixed interpolation
</code></pre>

### Mixing in behaviour {#mixins-behaviour}

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
module Trackable
  def mark_complete(step)
    completed_steps &lt;&lt; step
  end

  def completed_steps
    @completed_steps ||= []
  end
end

class Lesson
  include Trackable

  attr_reader :title

  def initialize(title)
    @title = title
  end
end

lesson = Lesson.new(&quot;Blocks &amp; Iterators&quot;)
lesson.mark_complete(&quot;Watch video&quot;)
lesson.mark_complete(&quot;Write sample code&quot;)
puts &quot;Finished steps: #{lesson.completed_steps.join(&#39;, &#39;)}&quot;  # Fixed interpolation
</code></pre>

### Practice checklist

- Create a module with utility methods and include it in different classes
- Practice using constants within modules
- Experiment with namespacing to avoid name collisions
- Understand the difference between `include`, `extend`, and `prepend`
- Try implementing custom `method_missing` behavior
- Work with mutable vs immutable objects

Keep these helpers in mind as you move into file handling, tooling, and packaging in the next chapter.

Finish the Ruby track with [Chapter 6: Files, gems & next steps](/tutorials/files-gems-next-steps/).
