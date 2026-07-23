---
layout: tutorial
title: "Chapter 32 &ndash; Ruby Access Control"
permalink: /courses/ruby-basics/ruby-access-control/
difficulty: beginner
summary: Use `public`, `protected`, and `private` to shape how objects expose methods and state.
previous_tutorial:
  title: 'Chapter 31: "Overloading" Methods the Ruby Way'
  url: /courses/ruby-basics/ruby-overloading-methods/
next_tutorial:
  title: "Chapter 33: Ruby Exceptions"
  url: /courses/ruby-basics/ruby-exceptions/
related_tutorials:
  - title: "Writing Our Own Class"
    url: /courses/ruby-basics/writing-our-own-class/
  - title: "Ruby Open Classes"
    url: /courses/ruby-basics/ruby-open-classes/
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
class Account
  attr_reader :balance
  protected :balance
end
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

# TODO: Define a class with protected attr_reader and show that outside callers fail.

```solution
class Account
  def initialize(balance)
    @balance = balance
  end

  def show_balance
    balance  # works - called without explicit receiver
  end

  protected

  attr_reader :balance
end

account = Account.new(100)

begin
  account.balance
rescue NoMethodError => e
  puts "Cannot access protected method from outside: #{e.message}"
end

puts "Balance via public method: #{account.show_balance}"
```

```test
out = output.string
raise "expected protected message" unless out.include?("Cannot access protected method from outside")
raise "expected balance output" unless out.include?("Balance via public method: 100")
```

#!


#### Practice 2 - Private helpers and explicit receivers

**Goal:** Create a private helper and see what happens when you call it with an explicit receiver.

#> ruby :practice

# TODO: Create a private helper and show what happens when called with an explicit receiver.

```solution
class Greeter
  def call
    hello  # works - called without explicit receiver
  end

  private

  def hello
    "hello"
  end
end

greeter = Greeter.new
puts "Via public method: #{greeter.call}"

begin
  greeter.hello  # explicit receiver triggers NoMethodError
rescue NoMethodError => e
  puts "Cannot call private method with explicit receiver: #{e.message}"
end
```

```test
out = output.string
raise "missing hello call" unless out.include?("Via public method:")
raise "missing private error" unless out.include?("Cannot call private method with explicit receiver:")
```

#!


#### Practice 3 - Comparison with protected getters

**Goal:** Build a comparison method that uses protected getters to keep state hidden.

#> ruby :practice

# TODO: Build a comparison method using protected getters to keep state hidden.

```solution
class Account
  def initialize(balance)
    @balance = balance
  end
  
  def richer_than?(other)
    balance > other.balance  # protected allows access from same class
  end
  
  protected
  
  attr_reader :balance
end

account1 = Account.new(100)
account2 = Account.new(50)

puts "Account1 richer than Account2? #{account1.richer_than?(account2)}"

begin
  account1.balance  # fails - protected from outside
rescue NoMethodError
  puts "Balance is protected and not accessible from outside"
end
```

```test
out = output.string
raise "missing comparison output" unless out.include?("Account1 richer than Account2? true")
raise "missing protected warning" unless out.include?("Balance is protected and not accessible from outside")
```

#!


#### Practice 4 - private_class_method factory

**Goal:** Use `private_class_method` to restrict a class-level factory method.

#> ruby :practice

# TODO: Use private_class_method to restrict a class-level factory method.

```solution
class Token
  def self.generate
    new
  end
  private_class_method :generate
  
  def self.create
    generate  # works - called from within the class
  end
end

token = Token.create
puts "Token created via public method: #{token.class}"

begin
  Token.generate  # fails - private class method
rescue NoMethodError => e
  puts "Cannot call private class method: #{e.message}"
end
```

```test
out = output.string
raise "missing public factory message" unless out.include?("Token created via public method: Token")
raise "missing private factory warning" unless out.include?("Cannot call private class method")
```

#!
