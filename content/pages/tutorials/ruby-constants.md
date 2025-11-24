---
layout: tutorial
title: "Chapter 42 &ndash; Ruby Constants"
permalink: /tutorials/ruby-constants/
difficulty: beginner
summary: Treat constants as stable names, understand Ruby's reassignment warnings, and use the scope operator to reach constants across classes and modules.
previous_tutorial:
  title: "Chapter 41: Understanding `self`"
  url: /tutorials/ruby-self/
next_tutorial:
  title: "Chapter 43: Socket Programming & Threads"
  url: /tutorials/ruby-socket-programming/
related_tutorials:
  - title: "Variables & Assignment"
    url: /tutorials/variables-and-assignment/
  - title: "Ruby Names"
    url: /tutorials/ruby-names/
---

> Adapted from Satish Talim's "Ruby Constants" lesson, refreshed for Typophic's modern walkthrough.

Constants behave like variables whose references are meant to stay fixed for the lifetime of the program. Ruby favors conventions over enforcement: you _can_ reassign a constant, but the interpreter will warn you so you know you're breaking expectations.

### Ruby warns on reassignment

Constant names start with an uppercase letter. Conventional style uses screaming snake case (`MAX_ATTEMPTS`, `PI`), while class/module names stay in CamelCase. Ruby only creates the constant once it's assigned.

```ruby-exec
# p054constwarn.rb
A_CONST = 10
A_CONST = 20
```

Running that script emits `warning: already initialized constant A_CONST`. The code still runs, but future readers now have to wonder if the change was intentional--treat the warning as a smell, not a feature.

### Mutating referenced objects is allowed

The "no changes" rule applies to the _binding_, not the object. If a constant points at a mutable value (like a string or array), you can mutate that value without touching the binding.

```ruby-exec
# p055constalter.rb
A_CONST = "Doshi"
B_CONST = A_CONST
A_CONST[0] = "J"

puts A_CONST  # Joshi
puts B_CONST  # Joshi -- both names reference the same object
```

Rails and other frameworks lean on this behavior: they freeze or mutate structures referenced by constants during boot to keep configuration in one place.

### Scope and the `::` operator

Constants live in Ruby's lexical scope. You can read them directly inside the class or module where they're defined. From the outside, reach in with the scope operator.

```ruby-exec
OUTER_CONST = 99

class Const
  CONST = OUTER_CONST + 1

  def get_const
    CONST
  end
end

puts Const.new.get_const #=> 100
puts Const::CONST        #=> 100
puts ::OUTER_CONST       #=> 99
puts Const::NEW_CONST = 123
```

Key rules:

- Use `Namespace::CONST` to reference constants defined elsewhere.
- You can open an existing class/module and define new constants on it.
- Constants can't be declared inside methods; define them at class/module scope instead.

### Constants next to other Ruby variables

The original RubyLearning example contrasts globals, class variables, instance variables, and constants in one class. It's noisy, but handy for seeing scoping rules in action.

```ruby-exec
# p057mymethods2.rb
$glob = 5

class TestVar
  @@cla = 6
  CONST_VAL = 7

  def initialize(x)
    @inst = x
    @@cla += 1
  end

  def self.cla
    @@cla
  end

  def self.cla=(value)
    @@cla = value
  end

  def inst
    @inst
  end

  def inst=(value)
    @inst = value
  end
end

test = TestVar.new(3)
puts $glob          # global variable
puts TestVar.cla    # class variable via reader
puts TestVar::CONST_VAL
test.inst = 8
puts test.inst
```

Pick the narrowest scope that communicates intent: prefer constants over globals, prefer readers/writers over directly exposing instance variables, and reserve class variables for data truly shared by every instance of the class.

### Practice checklist

- [ ] Reassign a constant in `irb` and observe the warning (then undo it).
- [ ] Store a mutable object (string, array, hash) in a constant and mutate it to see how references behave.
- [ ] Access a constant through nested namespaces using the scope operator.
- [ ] Attempt to define a constant inside a method so you can see Ruby's error firsthand.
- [ ] Freeze a constant (`CONFIG = {...}.freeze`) and try to mutate it to understand when immutability is enforced at the object level.

Next up: keep working through Flow Control & Collections so you can put these naming rules into practice while you branch, loop, and build enumerable data.

#### Practice 1 - Reassigning constants

**Goal:** Demonstrate what happens when you reassign a constant.

#> ruby :practice

# TODO: Print a short snippet that shows reassigning a constant like
# PI and noting that Ruby warns about it.

```solution
PI = 3.14
PI = 3.14159

puts "PI is now #{PI}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('PI is now') }
```

#!


#### Practice 2 - Mutable objects in constants

**Goal:** Store a mutable object in a constant and show how mutation behaves.

#> ruby :practice

# TODO: Print a snippet where a constant holds a hash or array that is
# mutated without reassigning the constant itself.

```solution
CONFIG = { retries: 3 }
CONFIG[:timeout] = 10

puts "CONFIG: #{CONFIG.inspect}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('CONFIG:') }
```

#!


#### Practice 3 - Namespaced constants

**Goal:** Access a constant through nested namespaces using `::`.

#> ruby :practice

# TODO: Print a couple of examples of constants accessed via the scope
# operator from nested modules or classes.

```solution
module MyApp
  module Models
    class User
      DEFAULT_ROLE = "viewer"
    end
  end
end

puts "Math::PI = #{Math::PI}"
puts "Default role: #{MyApp::Models::User::DEFAULT_ROLE}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('Math::PI') } && lines.any? { |l| l.include?('Default role') }
```

#!


#### Practice 4 - Constants inside methods

**Goal:** Attempt to define a constant inside a method and note Ruby's error.

#> ruby :practice

# TODO: Print a snippet that tries to define a constant inside a
# method and mention the dynamic constant assignment error.

```solution
code = <<~RUBY
  def define_bad_constant
    INSIDE = 1
  end
RUBY

begin
  eval(code)
rescue SyntaxError => e
  puts "Error defining constant inside method: #{e.class}: #{e.message}"
end
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('error defining constant') }
```

#!


#### Practice 5 - Freezing constants

**Goal:** Freeze a constant and try to mutate it to see where immutability is enforced.

#> ruby :practice

# TODO: Print a snippet where a constant hash is frozen and a comment
# about the FrozenError raised when modifying it.

```solution
SETTINGS = { cache: true }.freeze

begin
  SETTINGS[:cache] = false
rescue => e
  puts "Freeze prevents mutation: #{e.class}"
end
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('Freeze prevents mutation') }
```

#!
