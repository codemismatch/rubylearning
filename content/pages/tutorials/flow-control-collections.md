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

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
scores = { &quot;Satish&quot; =&gt; 92, &quot;Matz&quot; =&gt; 99, &quot;Yukihiro&quot; =&gt; 100 }

scores.each do |name, score|
  level = if score &gt;= 95
  &quot;expert&quot;
elsif score &gt;= 80
  &quot;intermediate&quot;
else
  &quot;beginner&quot;
end

puts &quot;#{name} is an #{level}.&quot;
end

numbers = [1, 2, 3, 4, 5]
evens = numbers.select(&amp;:even?)
puts &quot;Even numbers: #{evens.join(&#39;, &#39;)}&quot;
</code></pre>

### Fun with Strings {#strings}

String literals are sequences of characters between single or double quotation marks. Ruby provides many methods to work with strings:

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
# Creating strings
single_quoted = &#39;This is a string with single quotes&#39;
double_quoted = &quot;This is a string with double quotes&quot;

# String interpolation only works with double quotes
name = &quot;Ruby&quot;
greeting = &quot;Hello, #{name}!&quot;
puts greeting

# Common string methods
phrase = &quot;Hello Ruby World&quot;
puts phrase.length              # 17
puts phrase.upcase              # &quot;HELLO RUBY WORLD&quot;
puts phrase.downcase            # &quot;hello ruby world&quot;
puts phrase.reverse             # &quot;dlroW ybuR olleH&quot;
puts phrase.include?(&quot;Ruby&quot;) # true
puts phrase[0, 5] # &quot;Hello&quot; (substring)
</code></pre>

### More on Strings {#more-strings}

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
# String operations
first_name = &quot;John&quot;
last_name = &quot;Doe&quot;
full_name = first_name + &quot; &quot; + last_name  # String concatenation
puts full_name

# Using string interpolation (preferred approach)
full_name = &quot;#{first_name} #{last_name}&quot;
puts full_name

# Splitting and joining strings
sentence = &quot;Ruby is awesome&quot;
words = sentence.split(&quot; &quot;)  # Split by space
puts words.join(&quot;-&quot;)         # Join with hyphens

# More string methods
text = &quot;  Ruby Programming  &quot;
puts text.strip              # Remove leading/trailing whitespace
puts text.lstrip             # Remove leading whitespace only
puts text.rstrip             # Remove trailing whitespace only
</code></pre>

### Getting Input from User {#input}

So far we have seen methods like `puts` that write to the screen. How does one accept user input? For this, Ruby provides the `gets` method (get string). In our interactive environment, you can test this functionality:

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
print &#39;What is your name? &#39;
name = gets.strip

print &#39;How many lessons have you finished? &#39;
lessons = Integer(gets, exception: false) || 0

puts &quot;Great work, #{name}! Lesson #{lessons + 1} is up next.&quot;
</code></pre>

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

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
# if-else-end construct
age = 20

if age &gt;= 18
  puts &quot;You are an adult&quot;
else
  puts &quot;You are a minor&quot;
end

# unless construct (opposite of if)
temperature = 5

unless temperature &gt; 20
  puts &quot;It&#39;s cold outside&quot;
end

# case statement
grade = &#39;B&#39;

case grade
when &#39;A&#39;
  puts &quot;Excellent!&quot;
when &#39;B&#39;
  puts &quot;Good job!&quot;
when &#39;C&#39;
  puts &quot;Average&quot;
else
  puts &quot;Needs improvement&quot;
end
</code></pre>

### Arrays {#arrays}

An Array is just a list of items in order. Every slot in the list acts like a variable: you can see what object a particular slot points to, change what it points to, or add and remove slots:

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
# Creating arrays
fruits = [&quot;apple&quot;, &quot;banana&quot;, &quot;orange&quot;]
numbers = [1, 2, 3, 4, 5]
mixed = [&quot;hello&quot;, 42, true, 3.14]

# Accessing array elements (0-indexed)
puts fruits[0]    # &quot;apple&quot;
puts fruits[-1] # &quot;orange&quot; (last element)

# Common array methods
fruits &lt;&lt; &quot;grape&quot;      # Add element to end
fruits.push(&quot;mango&quot;)   # Another way to add
puts fruits.length     # Size of array
puts fruits.include?(&quot;banana&quot;)  # Check if element exists

# Iterating through arrays
numbers.each do |num|
  puts num * 2
end
</code></pre>

### Ranges {#ranges}

The first and perhaps most natural use of ranges is to express a sequence. Sequences have a start point, an end point, and a way to produce successive values in the sequence:

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
# Creating ranges
range1 = 1..5      # Inclusive (1, 2, 3, 4, 5)
range2 = 1...5     # Exclusive (1, 2, 3, 4)

puts range1.to_a   # Convert to array: [1, 2, 3, 4, 5]
puts range2.to_a   # Convert to array: [1, 2, 3, 4]

# Range methods
puts (1..10).include?(5)  # true
puts (&#39;a&#39;..&#39;e&#39;).to_a      # [&quot;a&quot;, &quot;b&quot;, &quot;c&quot;, &quot;d&quot;, &quot;e&quot;]

# Using ranges in conditionals
score = 85
case score
when 0..59 then puts &quot;F&quot;
when 60..69 then puts &quot;D&quot;
when 70..79 then puts &quot;C&quot;
when 80..89 then puts &quot;B&quot;
when 90..100 then puts &quot;A&quot;
end
</code></pre>

### Symbols {#symbols}

A symbol looks like a variable name but it's prefixed with a colon. Examples: `:action`, `:line_items`. You don't have to pre-declare a symbol:

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
# Symbols are immutable and unique
status = :active
color = :blue

puts status.class  # Symbol
puts color.class   # Symbol

# Symbols vs strings
puts :name.object_id == :name.object_id  # true (same object)
puts &quot;name&quot;.object_id == &quot;name&quot;.object_id  # false (different objects)

# Symbols are often used as hash keys
user = { name: &quot;Alice&quot;, age: 30, active: true }
puts user[:name]    # &quot;Alice&quot;
puts user[:age]     # 30
</code></pre>

### Hashes {#hashes}

Hashes (sometimes known as associative arrays, maps, or dictionaries) are similar to arrays in that they are indexed collections of objects:

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
# Creating hashes
person = { &quot;name&quot; =&gt; &quot;John&quot;, &quot;age&quot; =&gt; 30 }
user = { name: &quot;Alice&quot;, email: &quot;alice@example.com&quot;, active: true }

# Accessing hash values
puts person[&quot;name&quot;]   # &quot;John&quot;
puts user[:name]      # &quot;Alice&quot;

# Adding and modifying hash values
person[&quot;city&quot;] = &quot;New York&quot;
user[:role] = &quot;admin&quot;

# Common hash methods
puts user.keys        # Array of all keys
puts user.values      # Array of all values
puts user.length      # Number of key-value pairs

# Iterating through hashes
user.each do |key, value|
  puts &quot;#{key}: #{value}&quot;
end
</code></pre>

### Random Numbers {#random}

Ruby comes with a random number generator. The method to get a randomly chosen number is `rand`:

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
# Random float between 0 and 1
puts rand

# Random integer between 0 and specified number (exclusive)
puts rand(10)        # Random number from 0 to 9
puts rand(1..100)    # Random number from 1 to 100

# Setting a seed for reproducible random numbers
srand(12345)
puts rand            # Will always return the same sequence
</code></pre>

### Practice checklist

- Practice string manipulation methods like `upcase`, `downcase`, `reverse`, `include?`, etc.
- Experiment with different control structures (`if/else`, `case`, `unless`)
- Create and manipulate arrays and hashes with various methods
- Try using ranges for sequence generation and condition checking
- Work with symbols and understand their difference from strings

When the logic feels natural, move ahead to [Chapter 3: Methods & blocks](/tutorials/methods-and-blocks/).
