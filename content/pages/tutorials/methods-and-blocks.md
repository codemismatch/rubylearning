---
layout: tutorial
title: Chapter 3 &ndash; Methods & blocks
permalink: /tutorials/methods-and-blocks/
difficulty: beginner
summary: Package behaviour into reusable methods and lean on Ruby blocks for expressive iteration.
previous_tutorial:
  title: "Chapter 2: Flow control & collections"
  url: /tutorials/flow-control-collections/
next_tutorial:
  title: "Chapter 4: Classes & objects"
  url: /tutorials/classes-and-objects/
related_tutorials:
  - title: "Classes & objects"
    url: /tutorials/classes-and-objects/
  - title: "Ruby practice examples"
    url: /posts/ruby-examples/
---

> Revived from RubyLearning's tutorials by Satish Talim, with updates for modern Ruby development.

Methods package behaviour, and Ruby's blocks let you pass snippets of work into those methods. Together they keep scripts readable and expressive.

### More on Ruby Methods {#more-methods}

If objects (such as strings, integers and floats) are the nouns of Ruby, then methods are the verbs. Methods define what actions an object can perform:

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
# Methods on strings
name = &quot;ruby&quot;
puts name.upcase # &quot;RUBY&quot;
puts name.capitalize  # &quot;Ruby&quot;
puts name.length # 4

# Methods on numbers
number = 10
puts number.even? # true
puts number.odd?      # false
puts number.times(3)  # 30

# Methods on arrays
arr = [1, 2, 3]
puts arr.first        # 1
puts arr.last         # 3
puts arr.length       # 3
</code></pre>

### Writing Your Own Ruby Methods {#writing-methods}

Let's look at writing our own methods in Ruby:

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
# Basic method definition
def greet
  puts &quot;Hello, World!&quot;
end

greet  # Call the method

# Method with parameters
def greet_name(name)
  puts &quot;Hello, #{name}!&quot;
end

greet_name(&quot;Alice&quot;)  # Call with argument

# Method with multiple parameters
def add_numbers(a, b)
  result = a + b
  puts &quot;#{a} + #{b} = #{result}&quot;
end

add_numbers(5, 3)
</code></pre>

### Method Parameters and Return Values {#method-parameters}

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
# Methods return the last evaluated expression
def square(x)
  x * x
end

result = square(5)
puts result  # 25

# Method with default parameters
def greet(name, greeting = &quot;Hello&quot;)
  &quot;#{greeting}, #{name}!&quot;
end

puts greet(&quot;Alice&quot;)           # Hello, Alice!
puts greet(&quot;Bob&quot;, &quot;Hi&quot;)       # Hi, Bob!

# Method with return statement
def divide(a, b)
  return &quot;Cannot divide by zero!&quot; if b == 0
  a / b
end

puts divide(10, 2)  # 5
puts divide(10, 0)  # Cannot divide by zero!
</code></pre>

### Scope in Ruby {#scope}

Scope refers to the reach or visibility of variables. Different types of variables have different scoping rules:

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
# Global variables (accessible everywhere, prefixed with $)
$global_var = &quot;I&#39;m global&quot;

def show_global
  puts $global_var  # Accessible in method
end

show_global

# Local variables
local_var = &quot;I&#39;m local&quot;

def show_local
  # local_var is not accessible here
  local_in_method = &quot;Local in method&quot;
  puts local_in_method
end

show_local

# Instance variables (will be covered more in classes)
class Example
  def initialize
    @instance_var = &quot;I&#39;m an instance variable&quot;
  end

  def show_instance
    puts @instance_var
  end
end

obj = Example.new
obj.show_instance
</code></pre>

### Blocks in Ruby {#blocks}

Ruby Code blocks (called closures in other languages) are definitely one of the coolest features of Ruby and are chunks of code between braces `{}` or between `do` and `end`:

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
# Block with braces
3.times { puts &quot;Hello from block!&quot; }

# Block with do/end
3.times do
  puts &quot;Hello from block!&quot;
end

# Block with parameter
3.times do |i|
  puts &quot;#{i+1}. Hello from block!&quot;
end

# Using each with blocks
[1, 2, 3].each { |num| puts &quot;Number: #{num}&quot; }

[1, 2, 3].each do |num|
  puts &quot;Number: #{num}&quot;
  puts &quot;Square: #{num * num}&quot;
end
</code></pre>

### Blocks and Yields {#blocks-yield}

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
def repeat(times, message)
  times.times do |index|
    yield(index + 1, message)
  end
end

repeat(3, &quot;Practice makes progress&quot;) do |count, text|
  puts &quot;#{count}. #{text}!&quot;
end

def wrap(value)
  &quot;&lt;&lt;&lt; #{value} &gt;&gt;&gt;&quot;
end

puts wrap(&quot;Ruby blocks rock&quot;)
</code></pre>

### Procs in Ruby {#procs}

Blocks are not objects, but they can be converted into objects of class Proc:

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
# Creating a Proc
my_proc = Proc.new { |x| puts x * 2 }

# Calling a Proc
my_proc.call(5)  # Outputs: 10

# Proc with parameters
greet_proc = Proc.new { |name| puts &quot;Hello, #{name}!&quot; }  # Fixed interpolation
greet_proc.call(&quot;Alice&quot;)

# Using Proc in a method
def process_numbers(numbers, proc_obj)
  numbers.each { |num| proc_obj.call(num) }
end

doubler = Proc.new { |x| puts x * 2 }
process_numbers([1, 2, 3], doubler)
</code></pre>

### Lambdas in Ruby {#lambdas}

Lambdas are similar to Procs but with stricter argument checking:

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
# Creating a lambda
my_lambda = lambda { |x| x * 2 }
# Alternative syntax
my_lambda = -&gt;(x) { x * 2 }

# Calling a lambda
result = my_lambda.call(5)
puts result  # 10

# Lambda with multiple arguments
multiplier = -&gt;(x, y) { x * y }
puts multiplier.call(4, 5)  # 20

# Difference between Proc and Lambda in argument checking
proc_example = Proc.new { |x, y| [x, y] }
lambda_example = -&gt;(x, y) { [x, y] }

puts proc_example.call(1)     # [1, nil] - no error
puts lambda_example.call(1)   # ArgumentError - too few arguments
</code></pre>

### Practice checklist

- Write methods with different numbers of parameters
- Experiment with default parameters and return values
- Practice using blocks with array methods like `each`, `map`, `select`
- Create and use Procs and lambdas
- Understand the differences between Procs and lambdas

Ready for more structure? Continue to [Chapter 4: Classes & objects](/tutorials/classes-and-objects/).