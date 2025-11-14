---
layout: tutorial
title: "Chapter 3 &ndash; First Ruby Program"
permalink: /tutorials/first-ruby-program/
author: Neeraj Doharey (@codemismatch) <neeraj.doharey@live.com>
difficulty: beginner
summary: Create and run your first Ruby program, learn about Ruby's interactive console (IRB), and understand basic Ruby syntax.
previous_tutorial:
  title: "Chapter 2: Modern Ruby Installation Guide"
  url: /tutorials/installation-setup/
next_tutorial:
  title: "Chapter 4: Ruby Features"
  url: /tutorials/ruby-features/
---

### Running Ruby Code

There are two main ways to run Ruby code:

#### 1. Interactive Ruby (IRB) - The Ruby Console

IRB is an interactive Ruby shell where you can type Ruby code and see immediate results. It's perfect for experimenting and learning.

Start IRB:

```bash
irb
```
You'll see a prompt like this:

```bash
irb(main):001:0>
```
Try these examples in IRB:

```bash
puts "Hello, World!"
3 + 4
"ruby".upcase
5.times { print "Ruby! " }
```
Exit IRB:

```bash
exit
```

#### 2. Ruby Files (.rb)

Create files with Ruby code that you can save and run repeatedly.

Create a file called `hello.rb:`

<pre class="language-ruby"><code class="language-ruby">
#!/usr/bin/env ruby
# My first Ruby program
puts &quot;Hello, World!&quot;
puts &quot;Welcome to Ruby programming!&quot;
</code></pre>

#### Creating Your First Program

Let's create a more comprehensive first program. Create a file called `first_program.rb`:

```text
#!/usr/bin/env ruby


# A simple Ruby program to demonstrate basic concepts
puts "=" * 40
puts "Welcome to Your First Ruby Program!"
puts "=" * 40

# Variables and basic operations
name = "Ruby Learner"
age = 25
temperature = 72.5
is_learning = true

puts "Hello, #{name}!"
puts "In 5 years, you'll be #{age + 5} years old."
puts "Current temperature: #{temperature}°F"

# Basic math operations
x = 10
y = 3
puts "\nMath Operations:"
puts "#{x} + #{y} = #{x + y}"
puts "#{x} - #{y} = #{x - y}"
puts "#{x} * #{y} = #{x * y}"
puts "#{x} / #{y} = #{x / y}"
puts "#{x} % #{y} = #{x % y}"

# String methods
message = "ruby programming is fun"
puts "\nString Methods:"
puts "Original: #{message}"
puts "Uppercase: #{message.upcase}"
puts "Capitalized: #{message.capitalize}"
puts "Reversed: #{message.reverse}"

# Arrays
fruits = ["apple", "banana", "orange", "grape"]
puts "\nMy favorite fruits:"
fruits.each { |fruit| puts "- #{fruit}" }

puts "\n" + "=" * 40
puts "Program completed successfully!"
puts "=" * 40
```

Run your program:

```bash
ruby first_program.rb
```
