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

```ruby-exec
square  = Proc.new { |x| x * x }
doubler = proc { |n| n * 2 }      # same as Proc.new

square.call(4)   #=> 16
doubler.call(5)  #=> 10
```

You can call a proc via `.call`, `.[]`, or `.()`; they're interchangeable.

### Lambdas vs procs

```ruby-exec
increment = lambda { |n| n + 1 }
arrow     = ->(n) { n * 3 }

increment.call(2) #=> 3
arrow.call(3)     #=> 9
```

Key differences:

- **Argument checking:** Lambdas enforce arity (argument count); plain `Proc` objects are lenient.
- **Return semantics:** `return` inside a lambda exits the lambda; `return` inside a plain proc exits the enclosing method.

### Blocks, `yield`, and `&`

Methods receive blocks implicitly and can invoke them with `yield`:

```ruby-exec
def call_block
  yield if block_given?
end

call_block { puts "Hello from the block" }
```

To turn a block into a proc parameter, add `&block` to the method signature:

```ruby-exec
def greet(name, &block)
  block.call(name) if block
end

greet("Satish") { |n| puts "Welcome, #{n}!" }
```

### Passing procs between objects

```ruby-exec
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
```

Procs are great for callbacks, iterators (`map`, `select`), and DSLs. Pass them with `&proc_obj` to methods expecting a block:

```ruby-exec
numbers = [1, 2, 3]
printer = ->(n) { puts "Number: #{n}" }
numbers.each(&printer)
```

### Handy helpers

- `Proc#arity` reports how many arguments a proc expects.
- `proc.respond_to?(:call)` or `method(:some_method).to_proc` help integrate with other APIs.

### Practice checklist

- [ ] Capture a block with `Proc.new` and store it in a hash for later use.
- [ ] Compare a lambda and a plain proc that both `return` from inside a method to observe the difference.
- [ ] Pass the same proc to multiple methods using the `&` syntax.
- [ ] Use `Proc#arity` to validate dynamic callbacks.

Next: continue into Flow Control & Collections where these callable objects shine inside iterators and event-driven code.

#### Practice 1 - Capturing blocks in a hash

**Goal:** Capture a block with `Proc.new` and store it in a hash for later use.

#> ruby :practice

# TODO: Print a snippet that captures a block with Proc.new and stores
# it in a hash of callbacks.

```solution
puts "callbacks = {}"
puts "callbacks[:success] = Proc.new { |msg| puts msg }"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('callbacks') } && lines.any? { |l| l.downcase.include?('proc.new') }
```

#!


#### Practice 2 - return in lambda vs proc

**Goal:** Compare a lambda and a plain proc that both `return` from inside a method.

#> ruby :practice

# TODO: Sketch two methods, one that uses a lambda with return and one
# that uses a plain proc with return, and print labelled results.

```solution
puts "def lambda_example"
puts "  l = -> { return 'from lambda' }"
puts "  l.call"
puts "  'lambda result'"
puts "end"
puts "def proc_example"
puts "  p = Proc.new { return 'from proc' }"
puts "  p.call"
puts "  'proc result (never reached)'"
puts "end"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('lambda result') } && lines.any? { |l| l.downcase.include?('proc result') }
```

#!


#### Practice 3 - Passing the same proc with & syntax

**Goal:** Pass the same proc to multiple methods using `&`.

#> ruby :practice

# TODO: Print a snippet where a single proc is passed into two
# different methods using &callback.

```solution
callback = Proc.new { |name| puts "called callback for #{name}" }
["a", "b"].each(&callback)
```

```test
out = output.string; lines = out.lines.map(&:strip).reject(&:empty?); lines.count { |l| l.downcase.include?('called callback') } >= 2
```

#!


#### Practice 4 - Validating callbacks with Proc#arity

**Goal:** Use `Proc#arity` to validate dynamic callbacks.

#> ruby :practice

# TODO: Print a small example that checks a proc's arity before
# accepting it as a callback.

```solution
puts "def register(callback)"
puts "  raise ArgumentError unless callback.arity == 1"
puts "end"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('arity') }
```

#!

