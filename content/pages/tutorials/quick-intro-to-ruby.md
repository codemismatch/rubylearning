---
layout: tutorial
title: "Super Fast Ruby Intro (20 minutes)"
permalink: /tutorials/quick-intro/
difficulty: beginner
summary: A single, runnable walkthrough that takes you from launching Ruby to writing your first class, iterating with blocks, and wiring up a tiny greeter script.
previous_tutorial:
  title: "Ruby Tutorials"
  url: /tutorials
next_tutorial:
  title: "Chapter 1: Meet Ruby"
  url: /tutorials/meet-ruby/
related_tutorials:
  - title: "Chapter 1: Meet Ruby"
    url: /tutorials/meet-ruby/
  - title: "Chapter 3: First Ruby Program"
    url: /tutorials/first-ruby-program/
---

> Don’t worry about covering *everything* here. This is a feel-good tour that should take about 20 minutes. You’ll see Ruby’s core ideas, run code in the browser, and be ready to dive into the full learning path.

### 1. Ruby as a calculator

Ruby is an expression-oriented language. You can use it like a calculator in an interactive shell or a script file.

Try running a few expressions in the code window:

<pre class="language-ruby"><code class="language-ruby">
# Numbers and basic arithmetic
1 + 2
5 * 10
7 / 2.0

# Strings and concatenation
"Hello" + " " + "Ruby"

# Boolean expressions
3 &lt; 5
10 == 2 * 5
</code></pre>

Every line is an expression that produces a value. When you call `puts`, Ruby prints that value:

<pre class="language-ruby"><code class="language-ruby">
puts 1 + 2
puts "Total: #{5 * 10}"
</code></pre>

### 2. Variables and string interpolation

Ruby variables spring into existence when you assign to them. Interpolation (`#{...}`) lets you embed Ruby expressions inside double-quoted strings.

<pre class="language-ruby"><code class="language-ruby">
name = "Rubyist"
age  = 7 + 6

message = "Hello, #{name}! You are #{age} years awesome."
puts message
</code></pre>

Try changing `name` and `age` and re-running the code. Notice how interpolation keeps the string readable.

### 3. Arrays, hashes, and iteration

Ruby has flexible collection types. Arrays are ordered lists; hashes map keys to values.

<pre class="language-ruby"><code class="language-ruby">
languages = ["Ruby", "Python", "Elixir"]

puts "Languages I like:"
languages.each do |lang|
  puts "- #{lang}"
end

config = { host: "localhost", port: 3000 }

puts "Connecting to #{config[:host]}:#{config[:port]}..."
</code></pre>

Blocks (`do ... end`) are Ruby’s way of passing chunks of code to methods such as `each`. We’ll lean on them again in a moment.

### 4. Writing your own method

Methods package behaviour under a name and can take parameters with defaults.

<pre class="language-ruby"><code class="language-ruby">
def greet(name = "world")
  "Hello, #{name}!"
end

puts greet("Ruby")
puts greet
</code></pre>

Ruby returns the last expression from a method automatically; no explicit `return` is needed in simple cases.

### 5. A tiny Greeter class

Ruby is object-oriented: almost everything is an object, and classes define how those objects behave.

Let’s build a minimal greeter that remembers a name.

<pre class="language-ruby"><code class="language-ruby">
class Greeter
  def initialize(name)
    @name = name         # instance variable, stored on the object
  end

  def greet
    "Hello, #{@name}!"
  end
end

greeter = Greeter.new("Ruby learner")
puts greeter.greet
</code></pre>

Instance variables start with `@` and are private to the object. Methods such as `greet` can read them.

### 6. Adding a little flexibility

Let’s evolve the greeter so it can say hello to one name or many names.

<pre class="language-ruby"><code class="language-ruby">
class Greeter
  def initialize(names)
    @names = Array(names)
  end

  def greet_all
    if @names.empty?
      puts "Hello, stranger!"
    else
      @names.each do |name|
        puts "Hello, #{name}!"
      end
    end
  end
end

single = Greeter.new("Rubyist")
single.greet_all

many = Greeter.new(%w[Alice Bob Charlie])
many.greet_all
</code></pre>

Here we lean on `Array(names)` to normalise either a single string or an array into an array we can iterate over.

### 7. Blocks and yield

Ruby’s blocks really shine when you *yield* control from your method to a block supplied by the caller.

<pre class="language-ruby"><code class="language-ruby">
def with_timing(label = "block")
  start = Time.now
  result = yield          # run the caller’s block
  finish = Time.now

  elapsed = (finish - start).round(4)
  puts "#{label} took #{elapsed} seconds"
  result
end

with_timing("sleeping") do
  sleep 0.2
end
</code></pre>

The block stays close to the call site, while `with_timing` handles the reusable before/after logic.

### 8. Putting it together: a tiny script

Finally, let’s combine input, a class, and iteration into a very small script. When you click **Run**, this will ask you for names via a browser prompt (powered by Ruby’s `gets` in WebAssembly).

<pre class="language-ruby"><code class="language-ruby">
class Greeter
  def initialize
    @names = []
  end

  def ask_for_names
    loop do
      print "Enter a name (or just press Enter to finish): "
      name = gets.chomp
      break if name.empty?
      @names &lt;&lt; name
    end
  end

  def greet_all
    if @names.empty?
      puts "No names given, but hello anyway!"
    else
      @names.each do |name|
        puts "👋 Hello, #{name}!"
      end
    end
  end
end

greeter = Greeter.new
greeter.ask_for_names
greeter.greet_all
</code></pre>

Type a few different names when the prompts appear to see the script respond.

### What next?

You’ve just:

- Run Ruby expressions and printed values.
- Worked with strings, arrays, hashes, and interpolation.
- Written your own method.
- Defined a class with an initializer and instance methods.
- Used blocks, `each`, and `yield` to express behaviour.
- Wired a tiny interactive script that talks to you.

When you’re ready to go deeper, head to the main learning path and start with **Chapter 1 – Meet Ruby**. Each chapter builds on this quick intro with more examples and interactive practice.

