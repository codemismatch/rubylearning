---
layout: tutorial
title: "Chapter 28 &ndash; Ruby Open Classes"
permalink: /tutorials/ruby-open-classes/
difficulty: beginner
summary: Reopen existing classes—even core ones—to add behavior, and learn when to patch responsibly.
previous_tutorial:
  title: "Chapter 27: Including Other Files"
  url: /tutorials/including-other-files/
next_tutorial:
  title: "Chapter 29: Ruby Inheritance"
  url: /tutorials/ruby-inheritance/
related_tutorials:
  - title: "Writing Our Own Class"
    url: /tutorials/writing-our-own-class/
  - title: "Ruby Symbols"
    url: /tutorials/ruby-symbols/
---

> Adapted from Satish Talim’s “Ruby Open Classes” lesson.

Ruby classes are **open**, meaning you can reopen them at any time to add or override methods—even built-in classes like `String` and `Integer`. This power fuels Ruby’s expressive DSLs, but it requires discipline.

### Simple example: adding to `String`

<pre class="language-ruby"><code class="language-ruby">
class String
  def saysomething
    "Satish " + self
  end
end

puts "Talim".saysomething   #=> "Satish Talim"
</code></pre>

Reopening `String` lets every string gain the `saysomething` method.

### Monkey-patching other classes

You can extend numeric classes too:

<pre class="language-ruby"><code class="language-ruby">
class Integer
  def squared
    self * self
  end
end

puts 3.squared   #=&gt; 9
</code></pre>

This pattern explains why built-in methods like `2.times { ... }` work—the core `Integer` class defines them. Any method you add becomes available to every object of that class.

### Use responsibly

- Patches are global. Overriding a common method (e.g., `String#length`) affects all code, including gems.
- Prefer refinements or wrapper modules when shipping libraries to avoid collisions.
- Clearly document custom patches so teammates aren’t surprised.

### Practice checklist

- [ ] Add a method to `Array` that returns the middle element, making sure odd/even sizes behave sensibly.
- [ ] Override `String#to_s` in a small script and observe the impact; revert afterward to avoid confusion.
- [ ] Implement a custom numeric helper (e.g., `5.minutes` returning seconds) and use it in a timer script.
- [ ] Explore refinements (`using ModuleName`) for safer, scoped patches.

Next: keep building in Flow Control & Collections, combining your augmented classes with loops and iterators, and then dive into Ruby Inheritance to organize related behavior.
