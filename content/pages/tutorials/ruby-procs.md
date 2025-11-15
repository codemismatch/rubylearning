---
layout: tutorial
title: "Chapter 26 &ndash; Ruby Procs & Lambdas"
permalink: /tutorials/ruby-procs/
difficulty: intermediate
summary: Capture blocks as objects with `Proc` and `lambda`, pass them around, and build flexible callbacks.
previous_tutorial:
  title: "Chapter 25: Ruby `method_missing`"
  url: /tutorials/ruby-method-missing/
next_tutorial:
  title: "Chapter 27: Including Other Files"
  url: /tutorials/including-other-files/
related_tutorials:
  - title: "Ruby Symbols"
    url: /tutorials/ruby-symbols/
  - title: "Writing Our Own Class"
    url: /tutorials/writing-our-own-class/
---

> Adapted from Satish Talim's original "Ruby Procs" lesson.

Blocks are anonymous snippets that you pass to methods. `Proc` and `lambda` capture those blocks as reusable objects--you can store them in variables, pass them around, and call them later.

### Creating procs

<pre class="language-ruby"><code class="language-ruby">
square  = Proc.new { |x| x * x }
doubler = proc { |n| n * 2 }      # same as Proc.new

square.call(4)   #=&gt; 16
doubler.call(5)  #=&gt; 10
</code></pre>

You can call a proc via `.call`, `.[]`, or `.()`; they're interchangeable.

### Lambdas vs procs

<pre class="language-ruby"><code class="language-ruby">
increment = lambda { |n| n + 1 }
arrow     = -&gt;(n) { n * 3 }

increment.call(2) #=&gt; 3
arrow.call(3)     #=&gt; 9
</code></pre>

Key differences:

- **Argument checking:** Lambdas enforce arity (argument count); plain `Proc` objects are lenient.
- **Return semantics:** `return` inside a lambda exits the lambda; `return` inside a plain proc exits the enclosing method.

### Blocks, `yield`, and `&`

Methods receive blocks implicitly and can invoke them with `yield`:

<pre class="language-ruby"><code class="language-ruby">
def call_block
  yield if block_given?
end

call_block { puts &quot;Hello from the block&quot; }
</code></pre>

To turn a block into a proc parameter, add `&block` to the method signature:

<pre class="language-ruby"><code class="language-ruby">
def greet(name, &amp;block)
  block.call(name) if block
end

greet(&quot;Satish&quot;) { |n| puts &quot;Welcome, #{n}!&quot; }
</code></pre>

### Passing procs between objects

<pre class="language-ruby"><code class="language-ruby">
class Greeter
  def initialize(name)
    @name = name
  end

  def welcome(proc_obj)
    proc_obj.call(@name)
  end
end

greet_proc = Proc.new { |n| puts "Welcome, #{n}!" }
Greeter.new("Satish").welcome(greet_proc)
</code></pre>

Procs are great for callbacks, iterators (`map`, `select`), and DSLs. Pass them with `&proc_obj` to methods expecting a block:

<pre class="language-ruby"><code class="language-ruby">
numbers = [1, 2, 3]
printer = -&gt;(n) { puts &quot;Number: #{n}&quot; }
numbers.each(&amp;printer)
</code></pre>

### Handy helpers

- `Proc#arity` reports how many arguments a proc expects.
- `proc.respond_to?(:call)` or `method(:some_method).to_proc` help integrate with other APIs.

### Practice checklist

- [ ] Capture a block with `Proc.new` and store it in a hash for later use.
- [ ] Compare a lambda and a plain proc that both `return` from inside a method to observe the difference.
- [ ] Pass the same proc to multiple methods using the `&` syntax.
- [ ] Use `Proc#arity` to validate dynamic callbacks.

Next: continue into Flow Control & Collections where these callable objects shine inside iterators and event-driven code.
