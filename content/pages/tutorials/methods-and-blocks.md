---
layout: tutorial
title: "Chapter 3 &ndash; Methods & blocks"
permalink: /courses/ruby-basics/methods-and-blocks/
difficulty: beginner
summary: Package behaviour into reusable methods and lean on Ruby blocks for expressive iteration.
previous_tutorial:
  title: "Chapter 2: Flow control & collections"
  url: /courses/ruby-basics/flow-control-collections/
next_tutorial:
  title: "Chapter 4: Classes & objects"
  url: /courses/ruby-basics/classes-and-objects/
related_tutorials:
  - title: "Classes & objects"
    url: /courses/ruby-basics/classes-and-objects/
  - title: "Ruby practice examples"
    url: /blog/ruby-examples/
---

> Revived from RubyLearning's tutorials by Satish Talim, with updates for modern Ruby development.

Methods package behaviour, and Ruby's blocks let you pass snippets of work into those methods. Together they keep scripts readable and expressive.

### More on Ruby Methods {#more-methods}

If objects (such as strings, integers and floats) are the nouns of Ruby, then methods are the verbs. Methods define what actions an object can perform:

```ruby-exec
# Methods on strings
name = "ruby"
puts name.upcase # "RUBY"
puts name.capitalize  # "Ruby"
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
```

### Writing Your Own Ruby Methods {#writing-methods}

Let's look at writing our own methods in Ruby:

```ruby-exec
# Basic method definition
def greet
  puts "Hello, World!"
end

greet  # Call the method

# Method with parameters
def greet_name(name)
  puts "Hello, #{name}!"
end

greet_name("Alice")  # Call with argument

# Method with multiple parameters
def add_numbers(a, b)
  result = a + b
  puts "#{a} + #{b} = #{result}"
end

add_numbers(5, 3)
```

### Method Parameters and Return Values {#method-parameters}

```ruby-exec
# Methods return the last evaluated expression
def square(x)
  x * x
end

result = square(5)
puts result  # 25

# Method with default parameters
def greet(name, greeting = "Hello")
  "#{greeting}, #{name}!"
end

puts greet("Alice")           # Hello, Alice!
puts greet("Bob", "Hi")       # Hi, Bob!

# Method with return statement
def divide(a, b)
  return "Cannot divide by zero!" if b == 0
  a / b
end

puts divide(10, 2)  # 5
puts divide(10, 0)  # Cannot divide by zero!
```

### Scope in Ruby {#scope}

Scope refers to the reach or visibility of variables. Different types of variables have different scoping rules:

```ruby-exec
# Global variables (accessible everywhere, prefixed with $)
$global_var = "I'm global"

def show_global
  puts $global_var  # Accessible in method
end

show_global

# Local variables
local_var = "I'm local"

def show_local
  # local_var is not accessible here
  local_in_method = "Local in method"
  puts local_in_method
end

show_local

# Instance variables (will be covered more in classes)
class Example
  def initialize
    @instance_var = "I'm an instance variable"
  end

  def show_instance
    puts @instance_var
  end
end

obj = Example.new
obj.show_instance
```

### Blocks in Ruby {#blocks}

Ruby Code blocks (called closures in other languages) are definitely one of the coolest features of Ruby and are chunks of code between braces `{}` or between `do` and `end`:

```ruby-exec
# Block with braces
3.times { puts "Hello from block!" }

# Block with do/end
3.times do
  puts "Hello from block!"
end

# Block with parameter
3.times do |i|
  puts "#{i+1}. Hello from block!"
end

# Using each with blocks
[1, 2, 3].each { |num| puts "Number: #{num}" }

[1, 2, 3].each do |num|
  puts "Number: #{num}"
  puts "Square: #{num * num}"
end
```

### Blocks and Yields {#blocks-yield}

```ruby-exec
def repeat(times, message)
  times.times do |index|
    yield(index + 1, message)
  end
end

repeat(3, "Practice makes progress") do |count, text|
  puts "#{count}. #{text}!"
end

def wrap(value)
  "<<< #{value} >>>"
end

puts wrap("Ruby blocks rock")
```

### Procs in Ruby {#procs}

Blocks are not objects, but they can be converted into objects of class Proc:

```ruby-exec
# Creating a Proc
my_proc = Proc.new { |x| puts x * 2 }

# Calling a Proc
my_proc.call(5)  # Outputs: 10

# Proc with parameters
greet_proc = Proc.new { |name| puts "Hello, #{name}!" }  # Fixed interpolation
greet_proc.call("Alice")

# Using Proc in a method
def process_numbers(numbers, proc_obj)
  numbers.each { |num| proc_obj.call(num) }
end

doubler = Proc.new { |x| puts x * 2 }
process_numbers([1, 2, 3], doubler)
```

### Lambdas in Ruby {#lambdas}

Lambdas are similar to Procs but with stricter argument checking:

```ruby-exec
# Creating a lambda
my_lambda = lambda { |x| x * 2 }
# Alternative syntax
my_lambda = ->(x) { x * 2 }

# Calling a lambda
result = my_lambda.call(5)
puts result  # 10

# Lambda with multiple arguments
multiplier = ->(x, y) { x * y }
puts multiplier.call(4, 5)  # 20

# Difference between Proc and Lambda in argument checking
proc_example = Proc.new { |x, y| [x, y] }
lambda_example = ->(x, y) { [x, y] }

puts proc_example.call(1)     # [1, nil] - no error
puts lambda_example.call(1)   # ArgumentError - too few arguments
```

### Practice checklist

- Write methods with different numbers of parameters
- Experiment with default parameters and return values
- Practice using blocks with array methods like `each`, `map`, `select`
- Create and use Procs and lambdas
- Understand the differences between Procs and lambdas

#### Practice 1 - Writing methods with parameters

**Goal:** Define methods with different numbers of parameters and call them.

#> ruby :practice

# TODO: Define at least two methods: one that takes a single
# parameter, and another that takes two or more parameters. Call
# them and print the results.

```solution
def greet(name)
  puts "Hello, #{name}"
end

def add(a, b)
  a + b
end

greet("Rubyist")
puts "Sum: #{add(2, 3)}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('hello') } && lines.any? { |l| l.downcase.include?('sum') }
```

#!


#### Practice 2 - Default parameters and return values

**Goal:** Experiment with default parameters and explicit return values.

#> ruby :practice

# TODO: Write a method that uses a default parameter, call it with
# and without an explicit value, and print the returned values.

```solution
def welcome(name = "guest")
  "Welcome, #{name}"
end

puts welcome
puts welcome("Alex")
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('guest') } && lines.any? { |l| l.downcase.include?('alex') }
```

#!


#### Practice 3 - Using blocks with array methods

**Goal:** Practise using blocks with `each`, `map`, and `select`.

#> ruby :practice

# TODO: Create an array and use blocks with each, map, and select to
# transform and filter it, printing each step with a label.

```solution
nums = [1, 2, 3, 4, 5]

nums.each { |n| puts "each: #{n}" }

mapped = nums.map { |n| n * 2 }
puts "mapped: #{mapped.inspect}"

selected = nums.select(&:even?)
puts "selected: #{selected.inspect}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('mapped') } && lines.any? { |l| l.downcase.include?('selected') }
```

#!


#### Practice 4 - Creating and using Procs and lambdas

**Goal:** Create Procs and lambdas and invoke them.

#> ruby :practice

# TODO: Create a Proc and a lambda that each print or return a simple
# message, then call them using both .call and [] syntax.

```solution
my_proc = Proc.new { |name| puts "proc: Hello, #{name}" }
my_lambda = ->(name) { puts "lambda: Hello, #{name}" }

my_proc.call("Ruby")
my_proc["Rails"]

my_lambda.call("Ruby")
my_lambda["Rails"]
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('proc') } && lines.any? { |l| l.downcase.include?('lambda') }
```

#!


#### Practice 5 - Observing Proc vs lambda differences

**Goal:** Observe at least one behavioural difference between Procs and lambdas.

#> ruby :practice

# TODO: Write a small example that contrasts return behaviour or
# arity between a Proc and a lambda and print labelled results.

```solution
def proc_vs_lambda
  pr = Proc.new { |x, y| "proc result: #{x}, #{y.inspect}" }
  lm = ->(x, y) { "lambda result: #{x}, #{y}" }

  puts pr.call(1)
  puts lm.call(1, 2)
end

proc_vs_lambda
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('proc result') } && lines.any? { |l| l.downcase.include?('lambda result') }
```

#!


Ready for more structure? Continue to [Chapter 4: Classes & objects](/courses/ruby-basics/classes-and-objects/).
