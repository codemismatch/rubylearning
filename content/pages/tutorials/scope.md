---
layout: tutorial
title: "Chapter 8 &ndash; Scope"
permalink: /tutorials/scope/
difficulty: beginner
summary: Understand where your Ruby variables live, how global symbols behave, and why local scopes form around classes, modules, and methods.
previous_tutorial:
  title: "Chapter 7: Variables & Assignment"
  url: /tutorials/variables-and-assignment/
next_tutorial:
  title: "Chapter 9: Getting Input"
  url: /tutorials/getting-input/
related_tutorials:
  - title: "Variables & Assignment"
    url: /tutorials/variables-and-assignment/
  - title: "Ruby Features"
    url: /tutorials/ruby-features/
---

> Adapted from Satish Talim's "Scope" chapter on RubyLearning, updated with modern Ruby examples.

Scope describes where a variable is visible. Ruby keeps the rules straightforward: variable *prefixes* indicate intent, and structural keywords (`class`, `module`, `def`) carve out local bubbles.

### Global scope and `$globals`

Any identifier that starts with `$` is a **global variable**. It is accessible everywhere in your process and never goes out of scope.

```ruby-exec
$app_mode = "demo"

def banner
  "Running in #{$app_mode} mode"
end

puts banner           #=> "Running in demo mode"
```

Because global state is hard to reason about, most Rubyists limit themselves to the built-in globals Ruby provides automatically.

#### Handy built-in globals

- `$0` &mdash; The filename used to invoke the current program.
- `$:` &mdash; An array of directories Ruby searches when you `require` files.
- `$$` &mdash; The process ID of the current Ruby interpreter.

You can inspect them just like any other variable:

```ruby-exec
puts "Running #{$0} (PID #{$$})"
puts "Load path has #{$:.size} entries"
```

### Local scope rules

Locals are far more common than globals. Ruby (MRI) follows three big rules:

1. The **top level** (outside any class/module/method) has its own scope.
2. Each `class` or `module` block introduces a new local scope. Nested definitions get their own scopes too.
3. Every `def` creates a brand-new scope. Locals from the outer scope are not automatically visible unless captured in a block or passed in.

```ruby-exec
message = "outside"

class ScopeDemo
  message = "inside class"

  def self.print_messages
    message = "inside method"
    puts message
  end
end

ScopeDemo.print_messages  # prints "inside method"
puts message              # prints "outside"
```

Notice how each structural boundary protects its own copy of `message`.

### Blocks inherit, defs isolate

Blocks (`do..end`, `{}`) share their parent's local scope:

```ruby-exec
count = 0
3.times do
  count += 1
end
puts count #=> 3
```

Method definitions (`def`) always start fresh, so read/write outer locals via instance variables, accessors, or closures (e.g., lambdas) when needed.

### Practice checklist

- [ ] Print `$0`, `$$`, and the size of `$:` in a scratch script to see their values on your machine.
- [ ] Create nested `class`/`module` definitions and confirm each maintains its own `message` local.
- [ ] Compare a block's behaviour (which can increment an outer local) with a method definition (which cannot) using similar code.
- [ ] Refactor a small script to replace a global variable with an instance variable or dependency injection to reduce scope.

Next: Apply these scope rules as you branch and iterate inside Flow Control & Collections.

#### Practice 1 - Global special variables

**Goal:** Print `$0`, `$$`, and the size of `$:`.

#> ruby :practice

# TODO: Sketch a small script that prints $0, $$, and $:.size with
# labels so you can inspect them on your machine.

```solution
puts "$0: #{$0}"
puts "$$: #{$$}"
puts "$:.size: #{$:.size}"
```

```test
out = output.string; lines = out.lines.map(&:strip); %w[$0 $$ $:].all? { |tok| lines.any? { |l| l.include?(tok) } }
```

#!


#### Practice 2 - Nested class/module locals

**Goal:** Create nested `class`/`module` definitions and confirm each maintains its own `message` local.

#> ruby :practice

# TODO: Print an example of nested definitions that each use a
# different message local variable.

```solution
puts "module Outer"
puts "  message = 'outer'"
puts "  class Inner"
puts "    message = 'inner'"
puts "  end"
puts "end"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('Outer') } && lines.any? { |l| l.include?('Inner') }
```

#!


#### Practice 3 - Block vs method scope

**Goal:** Compare a block's behaviour with a method definition using similar code.

#> ruby :practice

# TODO: Show a block that increments an outer local and a method that
# cannot modify it directly, printing both counts.

```solution
puts "count = 0"
puts "3.times { count += 1 } # block can see outer variable"
puts "def bump(count); count += 1; end # method gets a copy"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('block count') } && lines.any? { |l| l.downcase.include?('method count') }
```

#!


#### Practice 4 - Refactoring globals

**Goal:** Refactor a small script to replace a global variable with an instance variable or dependency injection.

#> ruby :practice

# TODO: Print before/after pseudo-code that replaces a global variable
# with an instance variable.

```solution
puts "$global = 1"
puts "class Refactored"
puts "  def initialize(value)"
puts "    @value = value"
puts "  end"
puts "end"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('$global') } && lines.any? { |l| l.include?('@value') }
```

#!

