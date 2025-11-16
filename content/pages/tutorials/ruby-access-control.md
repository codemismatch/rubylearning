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

Now outside callers can't do `account.balance`, but other `Account` objects still can inside methods like `richer_than?`.

### Private methods

Private methods can't be called with an explicit receiver--even `self`.

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

#### Practice 1 - Protected attribute readers

<p><strong>Goal:</strong> Turn `attr_reader` into a protected method and confirm outside callers fail.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-access-control"
     data-practice-index="0"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('protected') } && lines.any? { |l| l.downcase.include?('no method') }"><code class="language-ruby">
# TODO: Sketch a class that defines attr_reader, marks it protected,
# and show (via a comment or output) that outside callers would fail.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-access-control"
     data-practice-index="0"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-access-control:0">
puts "class Account"
puts "  protected attr_reader :balance"
puts "end"
puts "# Account.new.balance # => NoMethodError from outside the class"
</script>

#### Practice 2 - Private helpers and explicit receivers

<p><strong>Goal:</strong> Create a private helper and see what happens when you call it with an explicit receiver.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-access-control"
     data-practice-index="1"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('private') } && lines.any? { |l| l.downcase.include?('nomethoderror') }"><code class="language-ruby">
# TODO: Print a small example showing a private helper and a comment
# about the NoMethodError raised when using an explicit receiver.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-access-control"
     data-practice-index="1"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-access-control:1">
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
</script>

#### Practice 3 - Comparison with protected getters

<p><strong>Goal:</strong> Build a comparison method that uses protected getters to keep state hidden.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-access-control"
     data-practice-index="2"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('greater balance') }"><code class="language-ruby">
# TODO: Print a short snippet where two instances compare balances
# using a protected reader, without exposing it publicly.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-access-control"
     data-practice-index="2"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-access-control:2">
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
</script>

#### Practice 4 - private_class_method factory

<p><strong>Goal:</strong> Use `private_class_method` to restrict a class-level factory method.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-access-control"
     data-practice-index="3"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('private_class_method') }"><code class="language-ruby">
# TODO: Print an example of a factory method made private at the
# class level using private_class_method.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-access-control"
     data-practice-index="3"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-access-control:3">
puts "class Token"
puts "  def self.generate"
puts "    new"
puts "  end"
puts "  private_class_method :generate"
puts "end"
</script>
