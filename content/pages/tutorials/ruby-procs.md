---
layout: tutorial
title: "Chapter 26 &ndash; Ruby Procs & Lambdas"
permalink: /courses/ruby-basics/ruby-procs/
difficulty: intermediate
summary: Capture blocks as objects with `Proc` and `lambda`, pass them around, and build flexible callbacks.
previous_tutorial:
  title: "Chapter 25: Ruby `method_missing`"
  url: /courses/ruby-basics/ruby-method-missing/
next_tutorial:
  title: "Chapter 27: Including Other Files"
  url: /courses/ruby-basics/including-other-files/
related_tutorials:
  - title: "Ruby Symbols"
    url: /courses/ruby-basics/ruby-symbols/
  - title: "Writing Our Own Class"
    url: /courses/ruby-basics/writing-our-own-class/
date: 2025-11-14
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
callbacks = {}
callbacks[:success] = Proc.new { |msg| puts "SUCCESS: #{msg}" }
callbacks[:error] = Proc.new { |msg| puts "ERROR: #{msg}" }

callbacks[:success].call("Saved record")
callbacks[:error].call("Failed to save")
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('SUCCESS:') } && lines.any? { |l| l.include?('ERROR:') }
```

#!


#### Practice 2 - return in lambda vs proc

**Goal:** Compare a lambda and a plain proc that both `return` from inside a method.

#> ruby :practice

# TODO: Sketch two methods, one that uses a lambda with return and one
# that uses a plain proc with return, and print labelled results.

```solution
def lambda_example
  l = -> { return "from lambda" }
  l.call
  "lambda result"
end

def proc_example
  p = Proc.new { return "from proc" }
  p.call
  "proc result (never reached)"
end

puts "lambda_example => #{lambda_example}"
puts "proc_example => #{proc_example}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('lambda_example => lambda result') } && lines.any? { |l| l.include?('proc_example => from proc') }
```

#!


#### Practice 3 - Passing the same proc with & syntax

**Goal:** Pass the same proc to multiple methods using `&`.

#> ruby :practice

# TODO: Print a snippet where a single proc is passed into two
# different methods using &callback.

```solution
callback = Proc.new { |name| puts "called callback for #{name}" }

["alpha", "beta"].each(&callback)
{ foo: "bar", baz: "qux" }.each_key(&callback)
```

```test
out = output.string; lines = out.lines.map(&:strip).reject(&:empty?); lines.count { |l| l.downcase.include?('called callback') } >= 4
```

#!


#### Practice 4 - Validating callbacks with Proc#arity

**Goal:** Use `Proc#arity` to validate dynamic callbacks.

#> ruby :practice

# TODO: Print a small example that checks a proc's arity before
# accepting it as a callback.

```solution
def register(callback)
  raise ArgumentError, "callback must accept 1 arg" unless callback.arity == 1
  puts "Callback registered"
end

register(->(name) { puts "Hi #{name}" })

begin
  register(Proc.new { |a, b| puts a + b })
rescue ArgumentError => e
  puts "Rejected: #{e.message}"
end
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('Callback registered') } && lines.any? { |l| l.include?('Rejected:') }
```

#!
