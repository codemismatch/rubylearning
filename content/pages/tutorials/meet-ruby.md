---
layout: tutorial
title: "Chapter 1 &ndash; Meet Ruby"
permalink: /tutorials/meet-ruby/
difficulty: beginner
summary: Greet the world, explore Ruby objects, and learn how the console responds to your code.
next_tutorial:
  title: "Chapter 2: Modern Ruby Installation Guide"
  url: /tutorials/installation-setup/
related_tutorials:
  - title: "Flow control & collections"
    url: /tutorials/flow-control-collections/
  - title: Ruby resources
    url: /pages/resources/
---

> Revived from RubyLearning's tutorials by Satish Talim, with updates for modern Ruby development.

### Introduction {#introduction}

Welcome to the world of Ruby! Ruby is a dynamic, open-source programming language with a focus on simplicity and productivity. It has an elegant, natural syntax that is easy to read and write, making it a fantastic choice for both new and experienced programmers.
<p><p>
#### What is Ruby? {#what-is-ruby}

At its core, Ruby is a pure object-oriented language. In Ruby, everything is an object. Every piece of information and code can be given its own properties and actions. This consistent, object-oriented model makes the language logical and predictable.

Ruby was created in the mid-1990s by Yukihiro "Matz" Matsumoto in Japan. Matz blended parts of his favorite languages (like Perl, Smalltalk, Eiffel, Ada, and Lisp) to form a new language that balanced functional programming with imperative programming.

His guiding philosophy was the "Principle of Least Surprise" - meaning that Ruby should behave in a way that minimizes confusion for experienced users. The language is designed to be natural, not simple, and it strives to be a joy to use.

<p><p>
#### Why Learn Ruby? {#why-learn-ruby}

- Developer Happiness: Ruby's primary goal is to make programmers productive and happy. Its clean and readable syntax feels almost like writing plain English, which reduces the cognitive load of coding.

- The Power of Rails: Ruby gained massive popularity with the creation of Ruby on Rails, a powerful web application framework. Rails uses conventions over configurations, making it incredibly efficient to build robust web applications.

- Full-Stack Capability: From command-line tools and desktop applications to complex, database-driven websites, Ruby is a versatile language capable of handling a wide range of tasks.

- Vibrant Community: Ruby is supported by a friendly and passionate community. This means a wealth of free libraries (gems), extensive documentation, and plenty of help available online.
<p><p>
#### A Taste of Ruby Code {#a-taste-of-ruby-code}

One of the best ways to see Ruby's elegance is to look at its code. Here's a classic example: a program that prints "Hello, World!" to the screen.

<pre class="language-ruby" data-executable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
puts &quot;Hello, Ruby learner!&quot;
answer = 40 + 2
puts &quot;The answer is #{answer}.&quot;
greeting = &quot;hi&quot;
puts greeting.upcase
puts greeting.class
</code></pre>

Compare this to other languages, and you'll immediately notice its simplicity. The puts command is a simple, intuitive way to output a line.

Here's another example that highlights its object-oriented nature:
<pre class="language-ruby" data-executable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
5.times { puts &quot;We love Ruby!&quot; }
</code></pre>

This code tells the number 5 to execute the times method, which then runs the block of code (the part in curly braces) five times. It's a natural and readable way to express a loop.
Getting Started

This tutorial is designed to be your guide. We will start from the very beginning, covering how to install Ruby and run your first script, and then progress through the fundamental concepts that form the foundation of the language.

Ready to begin your journey? Let's dive in and discover why so many developers have fallen in love with Ruby