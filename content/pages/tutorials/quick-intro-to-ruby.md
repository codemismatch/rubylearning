---
layout: tutorial
title: "Super Fast Ruby Intro (40 minutes)"
permalink: /tutorials/quick-intro/
difficulty: beginner
summary: A single, runnable 40-minute tour from "Ruby as a calculator" to blocks, classes, a tiny DSL, an interactive script, and a handful of Ruby party tricks.
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

> This is a 40-minute Ruby wow session. Instead of reading a reference, you will walk a straight path: from "Ruby as a calculator" through blocks, classes, and a tiny DSL, then finish with some Ruby party tricks and an interactive script.

Each section has a code window. Read the comment, hit **Run**, then change something and run it again.

---

### Ruby as a friendly calculator

<pre class="language-ruby"><code class="language-ruby">
puts 1 + 2        # addition
puts 3 * 7        # multiplication
puts 10 / 4.0     # division (float)
puts 2**8         # exponent (2 to the power 8)
puts 5 + 3 * 10   # normal math precedence
</code></pre>

Ruby only shows results when you ask it to, so we use `puts` to print the answers like a tiny calculator.

---

### Everything is an object

<pre class="language-ruby"><code class="language-ruby">
42.class          # => Integer
"hello".upcase   # call a method on a String
:symbol.to_s     # convert a Symbol to a String
nil.class        # => NilClass
</code></pre>

Numbers, strings, symbols, and `nil` are all real objects with methods you can call.

Try adding `.methods.sort.take(5)` after one of the lines to peek at what it can do.

---

### Strings and interpolation

<pre class="language-ruby"><code class="language-ruby">
name = "Ruby"     # local variable
age  = 30

puts "Hello, #{name}!"                 # insert name into the string
puts "Ruby has been around for #{age} years."

multiline = "Line 1\nLine 2\nLine 3"   # \n makes a new line
puts multiline
</code></pre>

`#{...}` lets you inject any expression into a string. This is one of the reasons Ruby code often reads like a sentence.

Change the text and try adding your own variables.

---

### Arrays, blocks, and Enumerable

<pre class="language-ruby"><code class="language-ruby">
numbers = [1, 2, 3, 4, 5]                 # an Array

evens   = numbers.select { |n| n.even? }  # keep only even numbers
squares = numbers.map    { |n| n * n }    # transform each number

puts "Original: #{numbers.inspect}"
puts "Evens:    #{evens.inspect}"
puts "Squares:  #{squares.inspect}"
</code></pre>

Blocks (`{ |n| ... }` or `do ... end`) are little anonymous functions you can hand to methods like `map`, `select`, and `each`. Ruby's `Enumerable` module gives you a whole toolbox of these.

Change the block to double only the odd numbers, or to build a new array of strings like `"Number: 3"`.

---

### Hashes and symbols

<pre class="language-ruby"><code class="language-ruby">
scores = {
  ruby:   10,   # key is a Symbol, value is an Integer
  python: 9,
  java:   7
}

scores[:go] = 8  # add a new key/value pair

scores.each do |language, score|
  puts "#{language} => #{score}"
end
</code></pre>

Hashes are Ruby's flexible key/value store. Symbols like `:ruby` are lightweight, reusable identifiers that make great hash keys.

Try adding a new language or changing the scoring.

---

### Methods: naming tiny ideas

<pre class="language-ruby"><code class="language-ruby">
def greet(name)
  "Hello, #{name}!"         # last expression is the return value
end

def loud_greet(name)
  greet(name).upcase        # call another method we just defined
end

puts greet("Ruby")
puts loud_greet("Ruby")
</code></pre>

Methods let you give names to behaviour and build bigger ideas out of smaller ones.

Rename the methods or add a new one (for example `whisper_greet`) and call it.

---

### Classes and objects: your own types

<pre class="language-ruby"><code class="language-ruby">
class Greeter
  def initialize(name)
    @name = name            # instance variable belongs to this object
  end

  def hello
    "Hello, #{@name}!"      # use the instance variable
  end
end

g = Greeter.new("Rubyist")  # create a new Greeter object
puts g.hello
</code></pre>

Classes bundle data and behaviour. `Greeter.new("Rubyist")` creates an object with its own `@name`.

Add a `goodbye` method or change the greeting message.

---

### Open classes: teaching old classes new tricks

<pre class="language-ruby"><code class="language-ruby">
class String
  def shout
    upcase + "!!!"          # use existing String methods
  end
end

puts "ruby".shout
puts "hello, world".shout
</code></pre>

In Ruby you can reopen existing classes and add behaviour. This is one of Ruby's most famous "superpowers". Use it with care in real applications, but it is great for exploration.

Try adding `def title_case` to `String` and use it on a sentence.

---

### Blocks as little callbacks

<pre class="language-ruby"><code class="language-ruby">
def with_logging
  puts "Starting work..."                 # runs before the block
  result = yield                          # run the block and capture result
  puts "Finished. Result was #{result.inspect}"  # runs after the block
  result                                  # return the block's result
end

value = with_logging do
  10 * 10                                 # this is the block body
end

puts "Outside we still have: #{value}"
</code></pre>

The `yield` keyword "calls" the block that was passed to the method. This is how many Ruby libraries let you write neat internal DSLs.

Change the block to do something more interesting, like building an array, and see how the logging changes.

---

### Lambdas and closures: functions that remember

<pre class="language-ruby"><code class="language-ruby">
def make_counter
  count = 0          # local to this method, but captured by the lambda
  -> do
    count += 1
  end
end

counter = make_counter   # each call gets its own captured count
puts counter.call
puts counter.call
puts counter.call
</code></pre>

The lambda remembers the `count` variable from the method where it was created. This "remembering" is called a closure and is used all over Ruby code.

Try creating two separate counters and call them in different orders.

---

### Enumerable pipelines: small steps, big power

<pre class="language-ruby"><code class="language-ruby">
numbers = (1..20).to_a           # turn a Range into an Array

result = numbers
  .select { |n| n.even? }        # keep even numbers
  .map    { |n| n * n }          # square them
  .reject { |n| n > 200 }        # drop big ones

puts result.inspect              # show the final Array
</code></pre>

Chaining `select`, `map`, and `reject` lets you express "what" you want to do without drowning in loops.

Experiment with other steps like `group_by` or `sum`.

---

### A tiny configuration DSL

<pre class="language-ruby"><code class="language-ruby">
class Config
  attr_reader :settings

  def initialize(&block)
    @settings = {}             # plain Hash under the hood
    instance_eval(&block) if block   # run the block in this instance's context
  end

  def set(key, value)
    @settings[key] = value
  end
end

config = Config.new do
  set :adapter, "postgres"   # looks like a mini configuration language
  set :pool, 5
end

puts config.settings.inspect
</code></pre>

Inside the block, `self` is the config object, so calling `set` reads like a tiny Ruby DSL. Many gems and frameworks use this pattern.

Change the configuration keys or print them in a prettier way.

---

### A small interactive script with gets

<pre class="language-ruby"><code class="language-ruby">
print "What city do you live in? "   # print without a newline
city = gets.chomp                    # ask the user and remove the newline

print "What country is that in? "
country = gets.chomp

puts "You live in #{city}, #{country}. Nice!"
</code></pre>

In this playground `gets` is wired to a browser prompt, so when the code runs you will see a popup asking for input. You can type any city or country you like; the script only cares that it gets some text back.

---

### Bonus: Ruby party tricks (extra 20 minutes)

These are more advanced and a bit cheeky. They show off Ruby's flexible object model and syntax.

---

### Teaching Integer some math slang

<pre class="language-ruby"><code class="language-ruby">
class Integer
  def squared
    self * self     # "self" is the Integer we are calling on
  end

  def seconds
    self            # read nicely with "seconds"
  end

  def minutes
    self * 60       # 1.minute, 2.minutes, etc.
  end
end

puts 5.squared
puts 2.minutes
puts 10.minutes + 5.seconds
</code></pre>

Monkey patching `Integer` like this makes tiny scripts read closer to English. In real apps, do this only in very clear, well-named places.

---

### A tiny Money class with overloaded operators

<pre class="language-ruby"><code class="language-ruby">
class Money
  attr_reader :cents   # expose the amount in cents

  def initialize(cents)
    @cents = cents
  end

  def +(other)
    Money.new(cents + other.cents)  # add two Money values
  end

  def *(n)
    Money.new(cents * n)            # multiply by a number
  end

  def to_s
    format("$%.2f", cents / 100.0)  # pretty string like "$3.50"
  end
end

coffee   = Money.new(350)
sandwich = Money.new(550)

puts coffee + sandwich
puts (coffee + sandwich) * 3
</code></pre>

Operators like `+` and `*` are just methods. You can give your own classes natural-feeling arithmetic.

---

### Bang methods that wrap safer ones

<pre class="language-ruby"><code class="language-ruby">
class String
  def shout!
    replace(upcase + "!!!")   # mutate the original string in-place
  end
end

name = "ruby"
name.shout!
puts name
</code></pre>

By convention, `!` means "dangerous" or "mutating". Here `shout!` permanently changes the string instead of returning a new one.

---

### Auto-logging every method call

<pre class="language-ruby"><code class="language-ruby">
class Logged
  def self.log_calls!
    instance_methods(false).each do |name|
      original = instance_method(name)

      define_method(name) do |*args, &block|
        puts "[LOG] calling #{name}(#{args.inspect})"  # before
        original.bind(self).call(*args, &block)       # call the real method
      end
    end
  end
end

class Calculator < Logged
  def add(a, b)
    a + b          # simple methods, logging is added by the parent class
  end

  def mul(a, b)
    a * b
  end

  log_calls!
end

calc = Calculator.new
puts calc.add(2, 3)
puts calc.mul(4, 5)
</code></pre>

Metaprogramming lets you wrap every method on a class in one go and add cross-cutting behaviour like logging.

---

### Auto-vivifying nested hashes

<pre class="language-ruby"><code class="language-ruby">
tree = Hash.new { |hash, key| hash[key] = Hash.new(&hash.default_proc) }
  # for any missing key, create another hash with the same behaviour

tree[:europe][:france][:paris] = "Eiffel Tower"
tree[:asia][:japan][:tokyo]    = "Skytree"

p tree
</code></pre>

The default block calls itself, so missing keys automatically get another hash. You can build deep structures without `||=` everywhere.

---

### The mysterious flip-flop operator

<pre class="language-ruby"><code class="language-ruby">
lines = [
  "noise",
  "START",
  "keep this",
  "and this too",
  "STOP",   # flip-flop will turn off after this line
  "more noise"
]

lines.each do |line|
  puts line if (line == "START")..(line == "STOP")
end
</code></pre>

The range `(cond1)..(cond2)` inside `if` or `unless` acts like a tiny state machine, flipping on at `cond1` and off after `cond2`.

---

### Splat in parallel assignment

<pre class="language-ruby"><code class="language-ruby">
first, *middle, last = [1, 2, 3, 4, 5]

p first   # => 1
p middle  # => [2, 3, 4]
p last    # => 5
</code></pre>

The splat (`*`) lets you capture "the rest" of a list. It feels a bit like pattern matching for arrays.

---

### tap and the safe navigation operator

<pre class="language-ruby"><code class="language-ruby">
user = { name: "Rubyist", email: "ruby@example.com" }

handle = user
  .tap { |u| puts "Debug: #{u.inspect}" }  # peek at the value
  &.fetch(:email, nil)                     # safe lookup
  &.split("@")                             # only if not nil
  &.first

puts "Handle is: #{handle.inspect}"
</code></pre>

`tap` gives you a place to log or tweak an object in the middle of a chain. `&.` ("lonely operator") calls methods only when the receiver is not `nil`.

---

### Methods with operator-like names

<pre class="language-ruby"><code class="language-ruby">
class MagicArray < Array
  def <<(value)
    puts "Pushing #{value.inspect}"  # extra behaviour
    super
  end

  def empty?
    puts "Checking if empty..."      # extra behaviour
    super
  end
end

m = MagicArray.new
puts m.empty?
m << 1
puts m.empty?
</code></pre>

Ruby lets you define methods like `<<` and `empty?`, which makes APIs and DSLs read naturally.

---

### Conditional superclass at runtime

<pre class="language-ruby"><code class="language-ruby">
verbose = true

Base = verbose ? Struct.new(:name) : Object

class Greeter < Base
  def hello
    if respond_to?(:name) && name   # only works when Base has a :name field
      "Hello, #{name}!"
    else
      "Hello there!"
    end
  end
end

puts Greeter.new("Ruby").hello   # if Base is Struct
puts Greeter.new.hello           # if Base is Object
</code></pre>

Ruby evaluates the superclass expression when the class is defined, so you can choose behaviour at runtime.

---

### A tiny CLI-inspired script

<pre class="language-ruby"><code class="language-ruby">
line_no = 0

File.foreach(__FILE__) do |line|
  line_no += 1                     # $. is the built-in line counter; we roll our own here
  print "#{line_no}: #{line}"      # print line number and the original line
end
</code></pre>

This is similar to what Ruby's `-n` and `-p` command-line flags do: wrap your code in a loop that reads each line, optionally printing it.

---

### Where to go next

You have now seen, in order:

- Ruby as a calculator where everything is an object.
- Strings, arrays, hashes, and blocks.
- Methods, classes, and open classes.
- Blocks, lambdas, and a tiny configuration DSL.
- A short interactive script using `gets`.
- A handful of Ruby "party tricks": monkey patching core classes, overloading operators, auto-logging, flip-flops, splat tricks, and CLI-style processing.

When you are ready for a slower, more complete tour, jump into **Chapter 1 - Meet Ruby** and work through the main learning path with checklists and practice exercises. The ideas you just met will keep popping up in friendlier, more detailed form.
