---
layout: tutorial
title: "Chapter 32 &ndash; Ruby Access Control"
permalink: /tutorials/ruby-access-control/
difficulty: beginner
summary: Use `public`, `protected`, and `private` to shape how objects expose methods and state.
previous_tutorial:
  title: 'Chapter 31: "Overloading" Methods the Ruby Way'
  url: /tutorials/ruby-overloading-methods/
next_tutorial:
  title: "Chapter 33: Ruby Exceptions"
  url: /tutorials/ruby-exceptions/
related_tutorials:
  - title: "Writing Our Own Class"
    url: /tutorials/writing-our-own-class/
  - title: "Ruby Open Classes"
    url: /tutorials/ruby-open-classes/
---

> Adapted from Satish Talim's "Access Control" lesson.

Ruby offers three visibility levels for instance methods:

- `public` - callable from anywhere (default).
- `protected` - callable by any instance of the same class/module (commonly used for comparisons).
- `private` - callable only without an explicit receiver (implicit `self`).

### Basic example

```ruby-exec
class Account
  attr_reader :balance

  def initialize(balance)
    @balance = balance
  end

  def richer_than?(other)
    balance > other.balance  # allowed because accessors are public
  end

  private

  def audit!
    puts "Checking balance..."
  end
end
```

Move `attr_reader` under `protected` if you want only account instances to compare balances:

```ruby-exec
protected :balance
```

Now outside callers can't do `account.balance`, but other `Account` objects still can inside methods like `richer_than?`.

### Private methods

Private methods can't be called with an explicit receiver--even `self`.

```ruby-exec
class Motorcycle
  def start
    warm_up_engine
    puts "Vroom!"
  end

  private

  def warm_up_engine
    puts "Warming..."
  end
end

Motorcycle.new.start
```

Calling `bike.warm_up_engine` would raise `NoMethodError` because it uses an explicit receiver.

### Protected methods

Protected shines when comparing internal state:

```ruby-exec
class Person
  def initialize(age)
    @age = age
  end

  def older_than?(other)
    age > other.age
  end

  protected

  attr_reader :age
end
```

Here `other.age` works because both objects are `Person` instances.

### Practice checklist

- [ ] Turn `attr_reader`/`attr_writer` into protected methods and confirm outside callers fail.
- [ ] Create a private helper and try to call it with an explicit receiver to see the error.
- [ ] Build a comparison method that uses protected getters to keep state hidden.
- [ ] Use `private_class_method` to restrict a class-level factory method.

Next: continue into Flow Control & Collections where encapsulation keeps your iterating objects tidy.

#### Practice 1 - Protected attribute readers

**Goal:** Turn `attr_reader` into a protected method and confirm outside callers fail.

#> ruby :practice

# TODO: Sketch a class that defines attr_reader, marks it protected,
# and show (via a comment or output) that outside callers would fail.

```solution
puts "class Account"
puts "  protected attr_reader :balance"
puts "end"
puts "# Account.new.balance # => NoMethodError from outside the class"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('protected') } && lines.any? { |l| l.downcase.include?('no method') }
```

#!


#### Practice 2 - Private helpers and explicit receivers

**Goal:** Create a private helper and see what happens when you call it with an explicit receiver.

#> ruby :practice

# TODO: Print a small example showing a private helper and a comment
# about the NoMethodError raised when using an explicit receiver.

```solution
puts "class Greeter"
puts "  def call"
puts "    hello"
puts "  end"
puts ""
puts "  private"
puts "  def hello"
puts "    puts 'hello'"
puts "  end"
puts "end"
puts "# Greeter.new.hello # => NoMethodError (private method `hello' called)"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('private') } && lines.any? { |l| l.downcase.include?('nomethoderror') }
```

#!


#### Practice 3 - Comparison with protected getters

**Goal:** Build a comparison method that uses protected getters to keep state hidden.

#> ruby :practice

# TODO: Print a short snippet where two instances compare balances
# using a protected reader, without exposing it publicly.

```solution
puts "class Account"
puts "  protected attr_reader :balance"
puts ""
puts "  def initialize(balance)"
puts "    @balance = balance"
puts "  end"
puts ""
puts "  def richer_than?(other)"
puts "    balance > other.balance"
puts "  end"
puts "end"
puts "puts 'greater balance? -> ' + Account.new(10).richer_than?(Account.new(5)).to_s"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('greater balance') }
```

#!


#### Practice 4 - private_class_method factory

**Goal:** Use `private_class_method` to restrict a class-level factory method.

#> ruby :practice

# TODO: Print an example of a factory method made private at the
# class level using private_class_method.

```solution
puts "class Token"
puts "  def self.generate"
puts "    new"
puts "  end"
puts "  private_class_method :generate"
puts "end"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('private_class_method') }
```

#!

