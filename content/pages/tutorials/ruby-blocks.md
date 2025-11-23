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

```ruby-exec
[1, 2, 3].each { |n| puts n }
[1, 2, 3].each do |n|
  puts n
end
```

### Yielding to a block

Any method can take an implicit block. Call it with `yield`:

```ruby-exec
# p022codeblock.rb
def call_block
  puts "Start of method"
  yield
  yield
  puts "End of method"
end

call_block { puts "In the block" }
```

If no block is provided and you call `yield`, Ruby raises `LocalJumpError`. Guard with `block_given?`.

### Passing arguments to a block

`yield` accepts arguments; list block parameters between pipes:

```ruby-exec
# p023codeblock2.rb
def call_block
  yield("hello", 99)
end

call_block { |str, num| puts "#{str} #{num}" }
```

### Checking for a block

```ruby-exec
def try
  if block_given?
    yield
  else
    puts "no block"
  end
end

try                      #=> "no block"
try { puts "hello" }     #=> "hello"
try do puts "hello" end  #=> "hello"
```

### Blocks capture scope

Block parameters are local to the block, but referencing outer variables mutates them unless you deliberately shadow them.

```ruby-exec
x = 10
5.times do |x|
  puts "x inside block: #{x}"
end
puts "x outside block: #{x}" # 10 -- outer x untouched
```

Reassigning `x` inside the block without using it as a parameter will change the outer variable:

```ruby-exec
x = 10
5.times do |y|
  x = y
end
puts x # 4 -- last iteration value
```

Ruby 1.9+ introduced block-local variables to avoid accidental clobbering:

```ruby-exec
x = 10
5.times do |y; x|
  x = y
  puts "block-local x: #{x}"
end
puts "outer x: #{x}" # 10
```

The semicolon separates block parameters (`y`) from block-local variables (`x`).

### Practice checklist

- [ ] Write a method that yields twice and pass it a block that prints a message with iteration counts.
- [ ] Experiment with `block_given?` by calling a method with and without a block.
- [ ] Use a block to iterate over a range and collect values, then rewrite the same logic using `Enumerable#map`.
- [ ] Demonstrate the difference between block parameters, outer variables, and block-local variables using `;` syntax.

Next: continue to Flow Control & Collections to iterate with arrays, hashes, and enumerable helpers.

#### Practice 1 - Yielding multiple times

**Goal:** Write a method that yields twice and pass it a block that prints a message with iteration counts.

#> ruby :practice

# TODO: Define a method that yields at least twice and pass it a block
# that prints a message including the iteration number.

```solution
def twice
  2.times do |i|
    yield(i + 1)
  end
end

twice do |iteration|
  puts "iteration #{iteration}"
end
```

```test
out = output.string; lines = out.lines.map(&:strip).reject(&:empty?); lines.count { |l| l.downcase.include?('iteration') } >= 2
```

#!


#### Practice 2 - Using block_given?

**Goal:** Experiment with `block_given?` by calling a method with and without a block.

#> ruby :practice

# TODO: Write a method that behaves differently depending on whether
# block_given? is true, then call it with and without a block.

```solution
def maybe_yield
  if block_given?
    puts "with block"
    yield
  else
    puts "without block"
  end
end

maybe_yield
maybe_yield { puts "block ran" }
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('with block') } && lines.any? { |l| l.downcase.include?('without block') }
```

#!


#### Practice 3 - Range iteration vs map

**Goal:** Use a block to iterate over a range and collect values, then rewrite the same logic with `Enumerable#map`.

#> ruby :practice

# TODO: Iterate over a numeric range using an explicit loop and a
# block to collect values, then do the same with map and print both
# results.

```solution
range = 1..5

manual = []
range.each do |n|
  manual << n * 2
end
puts "manual: #{manual.inspect}"

mapped = range.map { |n| n * 2 }
puts "map:    #{mapped.inspect}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('manual:') } && lines.any? { |l| l.downcase.include?('map:') }
```

#!


#### Practice 4 - Block parameters vs outer and block-local variables

**Goal:** Demonstrate the difference between block parameters, outer variables, and block-local variables using `;` syntax.

#> ruby :practice

# TODO: Use a block with block-local variables to contrast the values
# of a parameter, an outer variable, and a block-local variable.

```solution
x = 10

puts "outer x before: #{x}"

3.times do |i; x|
  x = i
  puts "block-local x: #{x}"
end

puts "outer x after: #{x}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('outer x') } && lines.any? { |l| l.downcase.include?('block-local x') }
```

#!

