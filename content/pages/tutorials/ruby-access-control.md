---
layout: tutorial
title: "Chapter 32 &ndash; Ruby Access Control"
permalink: /tutorials/ruby-access-control/
difficulty: beginner
summary: Use `public`, `protected`, and `private` to shape how objects expose methods and state.
previous_tutorial:
  title: "Chapter 31: “Overloading” Methods the Ruby Way"
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

> Adapted from Satish Talim’s “Access Control” lesson.

Ruby offers three visibility levels for instance methods:

- `public` – callable from anywhere (default).
- `protected` – callable by any instance of the same class/module (commonly used for comparisons).
- `private` – callable only without an explicit receiver (implicit `self`).

### Basic example

<pre class="language-ruby"><code class="language-ruby">
class Account
  attr_reader :balance

  def initialize(balance)
    @balance = balance
  end

  def richer_than?(other)
    balance &gt; other.balance  # allowed because accessors are public
  end

  private

  def audit!
    puts &quot;Checking balance...&quot;
  end
end
</code></pre>

Move `attr_reader` under `protected` if you want only account instances to compare balances:

<pre class="language-ruby"><code class="language-ruby">
protected :balance
</code></pre>

Now outside callers can’t do `account.balance`, but other `Account` objects still can inside methods like `richer_than?`.

### Private methods

Private methods can’t be called with an explicit receiver—even `self`.

<pre class="language-ruby"><code class="language-ruby">
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
</code></pre>

Calling `bike.warm_up_engine` would raise `NoMethodError` because it uses an explicit receiver.

### Protected methods

Protected shines when comparing internal state:

<pre class="language-ruby"><code class="language-ruby">
class Person
  def initialize(age)
    @age = age
  end

  def older_than?(other)
    age &gt; other.age
  end

  protected

  attr_reader :age
end
</code></pre>

Here `other.age` works because both objects are `Person` instances.

### Practice checklist

- [ ] Turn `attr_reader`/`attr_writer` into protected methods and confirm outside callers fail.
- [ ] Create a private helper and try to call it with an explicit receiver to see the error.
- [ ] Build a comparison method that uses protected getters to keep state hidden.
- [ ] Use `private_class_method` to restrict a class-level factory method.

Next: continue into Flow Control & Collections where encapsulation keeps your iterating objects tidy.
