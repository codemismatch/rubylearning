---
layout: tutorial
title: "Chapter 25 &ndash; Ruby `method_missing`"
permalink: /tutorials/ruby-method-missing/
difficulty: intermediate
summary: Intercept unknown method calls with `method_missing` to build dynamic APIs or graceful fallbacks.
previous_tutorial:
  title: "Chapter 24: Writing Our Own Class"
  url: /tutorials/writing-our-own-class/
next_tutorial:
  title: "Chapter 26: Ruby Procs & Lambdas"
  url: /tutorials/ruby-procs/
related_tutorials:
  - title: "Ruby Procs"
    url: /tutorials/ruby-procs/
  - title: "Ruby Symbols"
    url: /tutorials/ruby-symbols/
---

> Adapted from Satish Talim's `method_missing` lesson.

When Ruby can't find a method while walking an object's method lookup path, it raises `NoMethodError`. Override `method_missing` to intercept those unhandled messages and respond dynamically.

### Basic pattern

<pre class="language-ruby"><code class="language-ruby">
# p012zmm.rb
class Dummy
  def method_missing(method_name, *args, &block)
    puts "There's no method called #{method_name} here -- please try again."
  end
end

Dummy.new.anything
</code></pre>

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
