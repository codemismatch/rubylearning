---
layout: tutorial
title: Chapter 1 – Meet Ruby
permalink: /tutorials/meet-ruby/
difficulty: beginner
summary: Greet the world, explore Ruby objects, and learn how the console responds to your code.
next_tutorial:
  title: "Chapter 2: Flow control & collections"
  url: /tutorials/flow-control-collections/
related_tutorials:
  - title: "Flow control & collections"
    url: /tutorials/flow-control-collections/
  - title: Ruby resources
    url: /pages/resources/
---

> Revived from RubyLearning's tutorials by Satish Talim, with updates for modern Ruby development.

### Introduction {#introduction}

Ruby is a dynamic, open source programming language with a focus on simplicity and productivity. It has an elegant syntax that is natural to read and easy to write. Everything in Ruby is an object—numbers, strings, even `true` and `false`. Start by making sure Ruby is installed (via `rbenv`, `rvm`, or the Windows installer), open a terminal, and run `irb` to explore interactively.

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
puts &quot;Hello, Ruby learner!&quot;
answer = 40 + 2
puts &quot;The answer is #{answer}.&quot;
greeting = &quot;hi&quot;
puts greeting.upcase
puts greeting.class
</code></pre>

### Getting Started with Ruby {#getting-started}

Ruby is an interpreted language that runs in your browser through our interactive widget. You can execute any Ruby code directly in the examples below without installing anything on your system. The browser widget uses Ruby WASM to run Ruby code safely and efficiently.

### Your first Ruby program {#first-ruby-program}

Ruby executes from top to bottom—there is no `main` method—so keep each script focused on one idea. Try the interactive example below:

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
puts &#39;Hello from the browser!&#39;
name = &#39;Ruby learner&#39;
puts &quot;Welcome, #{name}!&quot;
</code></pre>

### Core Language Features {#features}

Ruby has several distinctive characteristics:

- Ruby is free-form and case sensitive; indentation is for humans, not the interpreter
- Comments start with `#`; multi-line comments can be wrapped in `=begin`/`=end`
- Reserved keywords (`if`, `class`, `module`, etc.) shouldn't be used as identifiers unless prefixed with `@`, `@@`, or `$`
- `nil` and `false` are the only falsey values—everything else counts as truthy

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
puts nil ? &#39;truthy&#39; : &#39;falsey&#39;
puts 0    ? &#39;truthy&#39; : &#39;falsey&#39;
puts []   ? &#39;truthy&#39; : &#39;falsey&#39;  # Even empty arrays are truthy!
</code></pre>

### Numbers in Ruby {#numbers}

Ruby supports various numeric types:

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
# Integers
age = 25
population = 7_800_000_000  # Underscores for readability

# Floats
price = 19.99
pi = 3.14159

# Basic arithmetic
sum = 5 + 3
product = 4 * 6
quotient = 10 / 3  # Integer division in older Ruby versions
exact_quotient = 10.0 / 3  # Float division

puts &quot;Sum: #{sum}, Product: #{product}, Quotient: #{quotient}, Exact: #{exact_quotient.round(2)}&quot;
</code></pre>

### Variables and Assignment {#variables}

In Ruby, you assign values to variables using the `=` operator:

<pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
# Variable assignment - no need to declare type
name = &quot;Alice&quot;
age = 30
height = 5.6
is_student = true

# Ruby is dynamically typed
puts name.class    # =&gt; String
puts age.class     # =&gt; Integer
puts height.class  # =&gt; Float
puts is_student.class  # =&gt; TrueClass

# Variables can be reassigned to different types
name = 42
puts name.class    # =&gt; Integer
</code></pre>

### Practice checklist

- Launch `irb` and reproduce the snippets above
- Call `.class` on numbers, strings, and symbols to see their object types
- Experiment with string interpolation (`"#{}`) and concatenation
- Try creating and running a simple Ruby script file

Satisfied? Continue to [Chapter 2: Flow control & collections](/tutorials/flow-control-collections/).
