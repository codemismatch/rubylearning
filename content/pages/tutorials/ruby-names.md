---
layout: tutorial
title: "Chapter 10 &ndash; Ruby Names"
permalink: /courses/ruby-basics/ruby-names/
difficulty: beginner
summary: Learn how Ruby names distinguish locals, instances, classes, globals, and constants, plus see how Ruby treats objects and numeric types under the hood.
previous_tutorial:
  title: "Chapter 9: Getting Input"
  url: /courses/ruby-basics/getting-input/
next_tutorial:
  title: "Chapter 11: More on Ruby Methods"
  url: /courses/ruby-basics/more-on-ruby-methods/
related_tutorials:
  - title: "Scope"
    url: /courses/ruby-basics/scope/
  - title: "Variables & Assignment"
    url: /courses/ruby-basics/variables-and-assignment/
date: 2025-11-14
---

> Adapted from Satish Talim's "Ruby Names" lesson, with refreshed examples for the modern stack.

Ruby names refer to the labels you use for variables, methods, classes, modules, and constants. The first character signals Ruby's intent: lowercase for locals, `@` for instances, `@@` for class-level state, `$` for globals, and uppercase for constants.

### Variable families at a glance

```ruby-exec
sunil = "local"           # lowercase or _ prefix
$mode = "demo"            # global variable (avoid unless necessary)

class VariableFamilies
  @@registry = {}         # class variable shared across instances

  def initialize
    @count = 1            # instance variable belongs to self
  end

  def show(local_value)
    puts "local: #{local_value}"
    puts "instance: #{@count}"
    puts "class: #{@@registry.inspect}"
    puts "global: #{$mode}"
  end
end

VariableFamilies.new.show(sunil)
```

- **Local variables** start with a lowercase letter or underscore (`_transactions`). They spring into existence the first time you assign to them.
- **Instance variables** begin with `@` and always belong to the current object referenced by `self`.
- **Class variables** begin with `@@`. They are shared by a class and its subclasses; use sparingly because they are easy to misuse.
- **Global variables** start with `$` and are visible everywhere. Ruby also predefines many globals such as `$0` (script name) and `$:` (load path).

### Constants, classes, and modules

Constants start with a capital letter:

```ruby-exec
module MyMath
  PI = 3.1416
end

class MyPune
end
```

Ruby allows you to reassign constants but prints a warning. Treat them as immutable configuration or types such as class/module names.

### Method naming conventions

- Method names should start with a lowercase letter or `_`.
- Allowed suffixes: `?` for predicate methods (`empty?`), `!` for "dangerous" variants (`save!`), and `=` for attribute writers (`name=`).
- Use snake_case for multi-word names and ALL_CAPS for constant-style identifiers.

### Ruby is dynamically typed

Variables reference objects, and you can bind different object types to the same variable as needed:

```ruby-exec
# p007dt.rb
# Ruby is dynamic
x = 7         # Integer
x = "house"   # String
x = 7.5       # Float

'I love Ruby'.length
```

Ruby automatically manages references and garbage collection, so there is no separate "primitive" vs "object" concept--everything is an object.

### Numeric classes and huge values

Ruby handles large numbers transparently by switching between `Integer` (formerly `Fixnum`/`Bignum`) under the hood. Floats live under `Float`, a subclass of `Numeric`, and expose useful constants:

```ruby-exec
puts Float::DIG  # precision in decimal digits
puts Float::MAX  # largest Float for your architecture
```

Need to scale dramatically? Ruby keeps going:

```ruby-exec
rice_on_square = 1
64.times do |square|
  puts "On square #{square + 1} are #{rice_on_square} grain(s)"
  rice_on_square *= 2
end
```

By the final square you are counting trillions of grains--Ruby handles it seamlessly.

### Inspecting classes and `self`

Because everything is an object, you can always ask Ruby about its class or inspect itself:

```ruby-exec
puts "I am in class = #{self.class}"
puts "I am an object = #{self}"
puts "My private methods include: #{self.private_methods.sort.take(5)}..."
```

Blocks enhance readability too:

```ruby-exec
5.times { puts "Mice!" }
"Elephants Like Peanuts".length
```

### Practice checklist

- [ ] Declare one variable of each scope type (`local`, `@instance`, `@@class`, `$global`) and log them from inside a class to see which are accessible.
- [ ] Create a module with a constant, then try reassigning it to observe Ruby's warning.
- [ ] Write a script that prints `Float::DIG` and `Float::MAX` plus the class of a huge integer to confirm Ruby's automatic promotion.
- [ ] Reproduce the rice-on-a-chessboard example and experiment with different iteration counts to see how quickly the value grows.

Next: move into Flow Control & Collections to apply these naming rules inside loops and conditionals.

#### Practice 1 - Variable scopes

**Goal:** Declare variables of each scope type and log them from inside a class.

#> ruby :practice

# TODO: Sketch a snippet that uses a local, @instance, @@class, and
# $global variable and prints which ones are visible from where.

```solution
class ScopeWindow
  @@class_value = "class scope"
  $global_value = "global scope"

  def initialize
    @instance_value = "instance scope"
  end

  def show(local_value)
    puts "local: #{local_value}"
    puts "@instance: #{@instance_value}"
    puts "@@class: #{@@class_value}"
    puts "$global: #{$global_value}"
  end
end

local_value = "local scope"
ScopeWindow.new.show(local_value)
```

```test
out = output.string; lines = out.lines.map(&:strip); %w[local @instance @@class $global].all? { |tok| lines.any? { |l| l.include?(tok) } }
```

#!


#### Practice 2 - Module constants and warnings

**Goal:** Create a module with a constant and try reassigning it.

#> ruby :practice

# TODO: Print an example that defines and then reassigns a module
# constant, noting Ruby will warn about it.

```solution
module MyModule
  NAME = "original"
end

MyModule::NAME = "changed"
puts "MyModule::NAME is now #{MyModule::NAME}"
puts "Warning: Ruby will warn about already initialized constant when NAME changes."
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('MyModule::NAME') } && lines.any? { |l| l.downcase.include?('warning') }
```

#!


#### Practice 3 - Float limits and big integers

**Goal:** Print `Float::DIG`, `Float::MAX`, and the class of a huge integer.

#> ruby :practice

# TODO: Print Float::DIG, Float::MAX, and inspect the class of a very
# large integer literal.

```solution
puts "Float::DIG = #{Float::DIG}"
puts "Float::MAX = #{Float::MAX}"
puts "(10**50).class = #{(10**50).class}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('Float::DIG') } && lines.any? { |l| l.downcase.include?('bignum') || l.downcase.include?('integer') }
```

#!


#### Practice 4 - Rice-on-a-chessboard growth

**Goal:** Reproduce the rice-on-a-chessboard example and experiment with growth.

#> ruby :practice

# TODO: Print a small script that doubles grains each square and
# prints the total at the end.

```solution
total = 0
grains = 1

8.times do |square|
  total += grains
  puts "Square #{square + 1}: #{grains} grain(s)"
  grains *= 2
end

puts "Total grains: #{total}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('square') } && lines.any? { |l| l.downcase.include?('total') }
```

#!
