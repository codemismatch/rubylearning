---
layout: tutorial
title: Chapter 2 &ndash; Flow control & collections
permalink: /tutorials/flow-control-collections/
difficulty: beginner
summary: Practise branching logic and collection helpers so your scripts react to real data.
previous_tutorial:
  title: "Chapter 1: Meet Ruby"
  url: /tutorials/meet-ruby/
next_tutorial:
  title: "Chapter 3: Methods & blocks"
  url: /tutorials/methods-and-blocks/
related_tutorials:
  - title: "Methods & blocks"
    url: /tutorials/methods-and-blocks/
  - title: "Ruby practice examples"
    url: /blog/ruby-examples/
---

> Revived from RubyLearning's tutorials by Satish Talim, with updates for modern Ruby development.

Branches and loops let your program respond to data. Ruby's arrays and hashes give you flexible containers for organising that data. Try the examples and then tweak them&mdash;Ruby's dynamic nature makes experimentation fast.

### Branching and iteration {#control-flow}

```ruby-exec
scores = { "Satish" => 92, "Matz" => 99, "Yukihiro" => 100 }

scores.each do |name, score|
  level = if score >= 95
  "expert"
elsif score >= 80
  "intermediate"
else
  "beginner"
end

puts "#{name} is an #{level}."
end

numbers = [1, 2, 3, 4, 5]
evens = numbers.select(&:even?)
puts "Even numbers: #{evens.join(', ')}"
```

### Fun with Strings {#strings}

String literals are sequences of characters between single or double quotation marks. Ruby provides many methods to work with strings:

```ruby-exec
# Creating strings
single_quoted = 'This is a string with single quotes'
double_quoted = "This is a string with double quotes"

# String interpolation only works with double quotes
name = "Ruby"
greeting = "Hello, #{name}!"
puts greeting

# Common string methods
phrase = "Hello Ruby World"
puts phrase.length              # 17
puts phrase.upcase              # "HELLO RUBY WORLD"
puts phrase.downcase            # "hello ruby world"
puts phrase.reverse             # "dlroW ybuR olleH"
puts phrase.include?("Ruby") # true
puts phrase[0, 5] # "Hello" (substring)
```

### More on Strings {#more-strings}

```ruby-exec
# String operations
first_name = "John"
last_name = "Doe"
full_name = first_name + " " + last_name  # String concatenation
puts full_name

# Using string interpolation (preferred approach)
full_name = "#{first_name} #{last_name}"
puts full_name

# Splitting and joining strings
sentence = "Ruby is awesome"
words = sentence.split(" ")  # Split by space
puts words.join("-")         # Join with hyphens

# More string methods
text = "  Ruby Programming  "
puts text.strip              # Remove leading/trailing whitespace
puts text.lstrip             # Remove leading whitespace only
puts text.rstrip             # Remove trailing whitespace only
```

### Getting Input from User {#input}

So far we have seen methods like `puts` that write to the screen. How does one accept user input? For this, Ruby provides the `gets` method (get string). In our interactive environment, you can test this functionality:

```ruby-exec
print 'What is your name? '
name = gets.strip

print 'How many lessons have you finished? '
lessons = Integer(gets, exception: false) || 0

puts "Great work, #{name}! Lesson #{lessons + 1} is up next."
```

- Local variables start with a lowercase letter or underscore and spring into existence on assignment.
- `gets` reads a line from standard input (including the newline); `strip` trims it.
- Wrap conversions with `Integer(..., exception: false)` when you want `nil` instead of an exception.

### Names in Ruby {#names}

Ruby names are used to refer to constants, variables, methods, classes, and modules. The first character of a name helps Ruby distinguish between different types:

- **Local variables** start with a lowercase letter or underscore (`name`, `_temp`)
- **Instance variables** start with `@` (`@name`, `@email`)
- **Class variables** start with `@@` (`@@count`, `@@total`)
- **Global variables** start with `$` (`$stdout`, `$LOAD_PATH`)
- **Constants** start with an uppercase letter (`Name`, `PI`)
- **Methods** follow the same naming rules as local variables

### Simple Constructs {#constructs}

```ruby-exec
# if-else-end construct
age = 20

if age >= 18
  puts "You are an adult"
else
  puts "You are a minor"
end

# unless construct (opposite of if)
temperature = 5

unless temperature > 20
  puts "It's cold outside"
end

# case statement
grade = 'B'

case grade
when 'A'
  puts "Excellent!"
when 'B'
  puts "Good job!"
when 'C'
  puts "Average"
else
  puts "Needs improvement"
end
```

### Arrays {#arrays}

An Array is just a list of items in order. Every slot in the list acts like a variable: you can see what object a particular slot points to, change what it points to, or add and remove slots:

```ruby-exec
# Creating arrays
fruits = ["apple", "banana", "orange"]
numbers = [1, 2, 3, 4, 5]
mixed = ["hello", 42, true, 3.14]

# Accessing array elements (0-indexed)
puts fruits[0]    # "apple"
puts fruits[-1] # "orange" (last element)

# Common array methods
fruits << "grape"      # Add element to end
fruits.push("mango")   # Another way to add
puts fruits.length     # Size of array
puts fruits.include?("banana")  # Check if element exists

# Iterating through arrays
numbers.each do |num|
  puts num * 2
end
```

### Ranges {#ranges}

The first and perhaps most natural use of ranges is to express a sequence. Sequences have a start point, an end point, and a way to produce successive values in the sequence:

```ruby-exec
# Creating ranges
range1 = 1..5      # Inclusive (1, 2, 3, 4, 5)
range2 = 1...5     # Exclusive (1, 2, 3, 4)

puts range1.to_a   # Convert to array: [1, 2, 3, 4, 5]
puts range2.to_a   # Convert to array: [1, 2, 3, 4]

# Range methods
puts (1..10).include?(5)  # true
puts ('a'..'e').to_a      # ["a", "b", "c", "d", "e"]

# Using ranges in conditionals
score = 85
case score
when 0..59 then puts "F"
when 60..69 then puts "D"
when 70..79 then puts "C"
when 80..89 then puts "B"
when 90..100 then puts "A"
end
```

### Symbols {#symbols}

A symbol looks like a variable name but it's prefixed with a colon. Examples: `:action`, `:line_items`. You don't have to pre-declare a symbol:

```ruby-exec
# Symbols are immutable and unique
status = :active
color = :blue

puts status.class  # Symbol
puts color.class   # Symbol

# Symbols vs strings
puts :name.object_id == :name.object_id  # true (same object)
puts "name".object_id == "name".object_id  # false (different objects)

# Symbols are often used as hash keys
user = { name: "Alice", age: 30, active: true }
puts user[:name]    # "Alice"
puts user[:age]     # 30
```

### Hashes {#hashes}

Hashes (sometimes known as associative arrays, maps, or dictionaries) are similar to arrays in that they are indexed collections of objects:

```ruby-exec
# Creating hashes
person = { "name" => "John", "age" => 30 }
user = { name: "Alice", email: "alice@example.com", active: true }

# Accessing hash values
puts person["name"]   # "John"
puts user[:name]      # "Alice"

# Adding and modifying hash values
person["city"] = "New York"
user[:role] = "admin"

# Common hash methods
puts user.keys        # Array of all keys
puts user.values      # Array of all values
puts user.length      # Number of key-value pairs

# Iterating through hashes
user.each do |key, value|
  puts "#{key}: #{value}"
end
```

### Random Numbers {#random}

Ruby comes with a random number generator. The method to get a randomly chosen number is `rand`:

```ruby-exec
# Random float between 0 and 1
puts rand

# Random integer between 0 and specified number (exclusive)
puts rand(10)        # Random number from 0 to 9
puts rand(1..100)    # Random number from 1 to 100

# Setting a seed for reproducible random numbers
srand(12345)
puts rand            # Will always return the same sequence
```

### Practice checklist

- Practice string manipulation methods like `upcase`, `downcase`, `reverse`, `include?`, etc.
- Experiment with different control structures (`if/else`, `case`, `unless`)
- Create and manipulate arrays and hashes with various methods
- Try using ranges for sequence generation and condition checking
- Work with symbols and understand their difference from strings

#### Practice 1 - String manipulation drills

**Goal:** Practise common string methods such as `upcase`, `downcase`, `reverse`, and `include?`.

#> ruby :practice

# TODO: Pick a base string and call upcase, downcase, reverse, and
# include? on it, printing a short label and the result for each call.
# Hint:
#   - Show both the method name and the value so it's clear which is which.

```solution
phrase = "Flow Control"

puts "upcase:   #{phrase.upcase}"
puts "downcase: #{phrase.downcase}"
puts "reverse:  #{phrase.reverse}"
puts "include? 'Control': #{phrase.include?('Control')}"
```

```test
out = output.string; lines = out.lines.map(&:strip); %w[upcase downcase reverse include?].all? { |word| lines.any? { |l| l.downcase.include?(word) } }
```

#!


#### Practice 2 - Playing with control structures

**Goal:** Experiment with `if/else`, `case`, and `unless` in a single script.

#> ruby :practice

# TODO: Write a small script that uses if/else, case, and unless to
# branch based on a value (for example, a score or a role).
# Hint:
#   - Print a line that mentions each construct so you can see it ran.

```solution
score = 82

if score >= 90
  puts "if: excellent"
elsif score >= 60
  puts "if: passing"
else
  puts "if: needs work"
end

level = case score
when 0...60 then "low"
when 60...80 then "medium"
else "high"
end
puts "case: level is #{level}"

logged_in = true
unless logged_in == false
  puts "unless: user is logged in"
end
```

```test
out = output.string; lines = out.lines.map(&:strip); %w[if case unless].all? { |word| lines.any? { |l| l.downcase.include?(word) } }
```

#!


#### Practice 3 - Arrays and hashes in action

**Goal:** Create and manipulate arrays and hashes with various methods.

#> ruby :practice

# TODO: Build an array and a hash, then apply a few methods to each
# (such as map, select, merge, or delete_if) and print the results.

```solution
nums = [1, 2, 3, 4, 5]
evens = nums.select(&:even?)
puts "array: even numbers: #{evens.inspect}"

user = { name: "Ruby", role: "learner", points: 10 }
user[:points] += 5
puts "hash: #{user.inspect}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('array:') } && lines.any? { |l| l.downcase.include?('hash:') }
```

#!


#### Practice 4 - Using ranges for sequences and conditions

**Goal:** Use ranges for sequence generation and condition checking.

#> ruby :practice

# TODO: Generate a sequence using a range and use a range in a
# condition (for example, to check whether a value falls inside a band).

```solution
range = 1..5
puts "1..5 as array: #{range.to_a.inspect}"

value = 3
if range.include?(value)
  puts "#{value} is in range"
else
  puts "#{value} is outside range"
end
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('1..5') } && lines.any? { |l| l.downcase.include?('in range') }
```

#!


#### Practice 5 - Working with symbols

**Goal:** Work with symbols and see how they differ from strings.

#> ruby :practice

# TODO: Create a hash that uses symbols as keys and compare them to
# string keys, printing out classes and a couple of lookups.

```solution
person = { name: "Rubyist", role: "student" }

puts "Keys: #{person.keys.inspect}"
puts "name value: #{person[:name]}"
puts "Key class: #{person.keys.first.class} (symbol)"
puts "String key equal? #{:name == 'name'}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?(':name') } && lines.any? { |l| l.downcase.include?('symbol') }
```

#!


When the logic feels natural, move ahead to [Chapter 3: Methods & blocks](/tutorials/methods-and-blocks/).
