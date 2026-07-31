---
layout: tutorial
title: "Chapter 25 &ndash; Ruby `method_missing`"
permalink: /courses/ruby-basics/ruby-method-missing/
difficulty: intermediate
summary: Intercept unknown method calls with `method_missing` to build dynamic APIs or graceful fallbacks.
previous_tutorial:
  title: "Chapter 24: Writing Our Own Class"
  url: /courses/ruby-basics/writing-our-own-class/
next_tutorial:
  title: "Chapter 26: Ruby Procs & Lambdas"
  url: /courses/ruby-basics/ruby-procs/
related_tutorials:
  - title: "Ruby Procs"
    url: /courses/ruby-basics/ruby-procs/
  - title: "Ruby Symbols"
    url: /courses/ruby-basics/ruby-symbols/
date: 2025-11-14
---

> Adapted from Satish Talim's `method_missing` lesson.

When Ruby can't find a method while walking an object's method lookup path, it raises `NoMethodError`. Override `method_missing` to intercept those unhandled messages and respond dynamically.

### Basic pattern

```ruby-exec
# p012zmm.rb
class Dummy
  def method_missing(method_name, *args, &block)
    puts "There's no method called #{method_name} here -- please try again."
  end
end

Dummy.new.anything
```

Output:

```
There's no method called anything here -- please try again.
```

Key details:

- `method_name` is the missing method's symbol.
- `*args` holds any positional arguments.
- `&block` references an optional block.
- Always call `super` when you don't handle the method so Ruby's default behavior (raising `NoMethodError`) still occurs.

### Why use `method_missing`?

- Provide friendlier error messages (with suggestions, logging, etc.).
- Implement dynamic finders (`find_by_name`, `find_by_email`, ...) in frameworks like Rails.
- Proxy calls to wrapped objects or remote services.

### Best practices

- Mirror Ruby's signature: `def method_missing(method_name, *args, &block)`.
- Implement `respond_to_missing?` alongside `method_missing` so tools like `respond_to?` and `method` stay accurate.
- Avoid swallowing unrelated errors--fall back to `super` unless you intentionally handle the message.
- Consider alternatives (`define_method`, delegation libraries) before reaching for `method_missing`; it can hide bugs when overused.

### Practice checklist

- [ ] Add `method_missing` to a class and log every unknown method before calling `super`.
- [ ] Build a simple dynamic finder (e.g., `user.find_by_name("...")`) that parses the method name inside `method_missing`.
- [ ] Override `respond_to_missing?` to keep `respond_to?` in sync with your dynamic methods.
- [ ] Experiment with passing blocks through `&block.call` inside your handler.

Next: continue to Flow Control & Collections to keep exercising these dynamic techniques inside larger programs.

#### Practice 1 - Logging unknown methods

**Goal:** Add `method_missing` to a class and log unknown methods before calling `super`.

#> ruby :practice

# TODO: Print a class definition that implements method_missing,
# logs the unknown method name, and calls super.

```solution
class LoggerProxy
  def method_missing(name, *args, &block)
    puts "unknown method: #{name} args=#{args.inspect}"
    super
  end
end

proxy = LoggerProxy.new

begin
  proxy.undefined_method(42)
rescue NoMethodError => e
  puts "Raised: #{e.class}"
end
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('unknown method') } && lines.any? { |l| l.include?('Raised: NoMethodError') }
```

#!


#### Practice 2 - Simple dynamic finder

**Goal:** Build a simple dynamic finder using `method_missing`.

#> ruby :practice

# TODO: Print a small sketch of a UserRepository class that responds
# to methods like find_by_name via method_missing by parsing the
# method name.

```solution
class UserRepository
  USERS = [
    { name: "Satish", email: "satish@example.com" },
    { name: "Ruby", email: "ruby@example.com" }
  ]

  def method_missing(name, *args)
    if name.to_s.start_with?("find_by_")
      field = name.to_s.sub("find_by_", "")
      match = USERS.find { |user| user[field.to_sym] == args.first }
      puts "dynamic finder for #{field} => #{match.inspect}"
    else
      super
    end
  end

  def respond_to_missing?(name, include_private = false)
    name.to_s.start_with?("find_by_") || super
  end
end

repo = UserRepository.new
repo.find_by_name("Satish")
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('dynamic finder for name') }
```

#!


#### Practice 3 - Keeping respond_to? honest

**Goal:** Override `respond_to_missing?` so `respond_to?` stays in sync with dynamic methods.

#> ruby :practice

# TODO: Print an example respond_to_missing? implementation that
# recognises your dynamic finder methods.

```solution
class DynamicFinder
  def method_missing(name, *args)
    return super unless name.to_s.start_with?("find_by_")
    puts "handling #{name}"
  end

  def respond_to_missing?(name, include_private = false)
    name.to_s.start_with?("find_by_") || super
  end
end

finder = DynamicFinder.new
puts "respond_to?(:find_by_email) => #{finder.respond_to?(:find_by_email)}"
puts "respond_to?(:foo) => #{finder.respond_to?(:foo)}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('respond_to?(:find_by_email) => true') } && lines.any? { |l| l.include?('respond_to?(:foo) => false') }
```

#!


#### Practice 4 - Passing blocks through handlers

**Goal:** Experiment with passing blocks through `&block` inside a `method_missing` handler.

#> ruby :practice

# TODO: Print a short example showing method_missing capturing a
# block argument and calling it.

```solution
class BlockForwarder
  def method_missing(name, *args, &block)
    if block
      block.call("yielded from block")
    else
      super
    end
  end
end

BlockForwarder.new.undefined do |message|
  puts "Block received: #{message}"
end
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('Block received: yielded from block') }
```

#!
