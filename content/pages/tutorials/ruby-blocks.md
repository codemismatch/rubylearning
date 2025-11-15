---
layout: tutorial
title: "Chapter 16 &ndash; Ruby Blocks"
permalink: /tutorials/ruby-blocks/
difficulty: beginner
summary: Learn how Ruby blocks capture context, pass arguments via `yield`, and use block-local variables to avoid clobbering outer state.
previous_tutorial:
  title: "Chapter 15: Simple Constructs"
  url: /tutorials/simple-constructs/
next_tutorial:
  title: "Chapter 17: Ruby Arrays"
  url: /tutorials/ruby-arrays/
related_tutorials:
  - title: "Methods & blocks"
    url: /tutorials/methods-and-blocks/
  - title: "Writing Your Own Ruby Methods"
    url: /tutorials/writing-own-ruby-methods/
---

> Adapted from Satish Talim's original Ruby Blocks lesson.

Blocks (closures) are chunks of code wrapped in `{}` or `do..end` that travel alongside method calls. Ruby captures the surrounding context (locals, `self`, etc.) and lets methods invoke the block with `yield`.

### Block syntax and precedence

- Use `{}` for single-line blocks, `do..end` for multi-line.
- `{}` has higher precedence; `do..end` binds to the method call even without parentheses. Be explicit when in doubt.

<pre class="language-ruby"><code class="language-ruby">
[1, 2, 3].each { |n| puts n }
[1, 2, 3].each do |n|
  puts n
end
</code></pre>

### Yielding to a block

Any method can take an implicit block. Call it with `yield`:

<pre class="language-ruby"><code class="language-ruby">
# p022codeblock.rb
def call_block
  puts "Start of method"
  yield
  yield
  puts "End of method"
end

call_block { puts "In the block" }
</code></pre>

If no block is provided and you call `yield`, Ruby raises `LocalJumpError`. Guard with `block_given?`.

### Passing arguments to a block

`yield` accepts arguments; list block parameters between pipes:

<pre class="language-ruby"><code class="language-ruby">
# p023codeblock2.rb
def call_block
  yield("hello", 99)
end

call_block { |str, num| puts "#{str} #{num}" }
</code></pre>

### Checking for a block

<pre class="language-ruby"><code class="language-ruby">
def try
  if block_given?
    yield
  else
    puts &quot;no block&quot;
  end
end

try                      #=&gt; &quot;no block&quot;
try { puts &quot;hello&quot; }     #=&gt; &quot;hello&quot;
try do puts &quot;hello&quot; end  #=&gt; &quot;hello&quot;
</code></pre>

### Blocks capture scope

Block parameters are local to the block, but referencing outer variables mutates them unless you deliberately shadow them.

<pre class="language-ruby"><code class="language-ruby">
x = 10
5.times do |x|
  puts &quot;x inside block: #{x}&quot;
end
puts &quot;x outside block: #{x}&quot; # 10 -- outer x untouched
</code></pre>

Reassigning `x` inside the block without using it as a parameter will change the outer variable:

<pre class="language-ruby"><code class="language-ruby">
x = 10
5.times do |y|
  x = y
end
puts x # 4 -- last iteration value
</code></pre>

Ruby 1.9+ introduced block-local variables to avoid accidental clobbering:

<pre class="language-ruby"><code class="language-ruby">
x = 10
5.times do |y; x|
  x = y
  puts &quot;block-local x: #{x}&quot;
end
puts &quot;outer x: #{x}&quot; # 10
</code></pre>

The semicolon separates block parameters (`y`) from block-local variables (`x`).

### Practice checklist

- [ ] Write a method that yields twice and pass it a block that prints a message with iteration counts.
- [ ] Experiment with `block_given?` by calling a method with and without a block.
- [ ] Use a block to iterate over a range and collect values, then rewrite the same logic using `Enumerable#map`.
- [ ] Demonstrate the difference between block parameters, outer variables, and block-local variables using `;` syntax.

Next: continue to Flow Control & Collections to iterate with arrays, hashes, and enumerable helpers.
