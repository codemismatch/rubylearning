---
layout: tutorial
title: "Chapter 31 &ndash; “Overloading” Methods the Ruby Way"
permalink: /tutorials/ruby-overloading-methods/
difficulty: beginner
summary: Ruby doesn’t have compile-time overloading, but optional args, splats, and keyword args give you flexible interfaces.
previous_tutorial:
  title: "Chapter 30: Overriding Methods"
  url: /tutorials/ruby-overriding-methods/
next_tutorial:
  title: "Chapter 32: Ruby Access Control"
  url: /tutorials/ruby-access-control/
related_tutorials:
  - title: "Writing Our Own Class"
    url: /tutorials/writing-our-own-class/
  - title: "Ruby Procs & Lambdas"
    url: /tutorials/ruby-procs/
---

> Adapted from Satish Talim’s “Overloading Methods” lesson.

Ruby doesn’t support traditional method overloading (same name, different signatures). Instead, you build flexible interfaces with default values, splats (`*args`), keyword arguments, and runtime dispatch.

### Optional and default arguments

<pre class="language-ruby"><code class="language-ruby">
def greet(name = &quot;friend&quot;)
  &quot;Hello, #{name}!&quot;
end

puts greet          #=&gt; &quot;Hello, friend!&quot;
puts greet(&quot;Satish&quot;) #=&gt; &quot;Hello, Satish!&quot;
</code></pre>

### Variable arguments with `*args`

<pre class="language-ruby"><code class="language-ruby">
def sum(*numbers)
  numbers.inject(0, :+)
end

puts sum            #=> 0
puts sum(1, 2, 3)   #=> 6
</code></pre>

You can inspect `numbers.length` or the class of each argument to branch as needed.

### Keyword arguments

<pre class="language-ruby"><code class="language-ruby">
def send_email(to:, subject:, body: &quot;Hello&quot;)
  # ...
end

send_email(to: &quot;team@example.com&quot;, subject: &quot;Reminder&quot;)
</code></pre>

Keyword args make call sites self-documenting and avoid argument-order bugs.

### Tips from the legacy lesson

- Lean on Ruby’s dynamic nature: check `args.length`, `args.first`, or presence of options to determine behavior.
- Don’t overdo it—too many code paths in a single method can get confusing. Prefer separate methods if behavior differs significantly.
- Consider using hashes (`options = {}`) or keyword arguments for clarity when mimicking overloads.

### Practice checklist

- [ ] Write a `log(message, level = :info)` method and call it with/without the second argument.
- [ ] Build a `rectangle_area(*args)` method that accepts either two numbers (`width`, `height`) or a hash (`width:`, `height:`).
- [ ] Use keyword arguments with defaults to simulate constructor overloading in a small class.
- [ ] Inspect `args.length` in a method and raise `ArgumentError` when the combination doesn’t make sense.

Next: keep applying these dynamic dispatch techniques inside Flow Control & Collections.
