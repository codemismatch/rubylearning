---
layout: tutorial
title: "Chapter 28 &ndash; Ruby Open Classes"
permalink: /courses/ruby-basics/ruby-open-classes/
difficulty: intermediate
summary: Reopen existing classes--even core ones--to add behavior, and learn when to patch responsibly.
previous_tutorial:
  title: "Chapter 27: Including Other Files"
  url: /courses/ruby-basics/including-other-files/
next_tutorial:
  title: "Chapter 29: Ruby Inheritance"
  url: /courses/ruby-basics/ruby-inheritance/
related_tutorials:
  - title: "Writing Our Own Class"
    url: /courses/ruby-basics/writing-our-own-class/
  - title: "Ruby Symbols"
    url: /courses/ruby-basics/ruby-symbols/
date: 2025-11-14
---

> Adapted from Satish Talim's "Ruby Open Classes" lesson.

Ruby classes are **open**, meaning you can reopen them at any time to add or override methods--even built-in classes like `String` and `Integer`. This power fuels Ruby's expressive DSLs, but it requires discipline.

### Simple example: adding to `String`

```ruby-exec
class String
  def saysomething
    "Satish " + self
  end
end

puts "Talim".saysomething   #=> "Satish Talim"
```

Reopening `String` lets every string gain the `saysomething` method.

### Monkey-patching other classes

You can extend numeric classes too:

```ruby-exec
class Integer
  def squared
    self * self
  end
end

puts 3.squared   #=> 9
```

This pattern explains why built-in methods like `2.times { ... }` work--the core `Integer` class defines them. Any method you add becomes available to every object of that class.

### Use responsibly

- Patches are global. Overriding a common method (e.g., `String#length`) affects all code, including gems.
- Prefer refinements or wrapper modules when shipping libraries to avoid collisions.
- Clearly document custom patches so teammates aren't surprised.

### Practice checklist

- [ ] Add a method to `Array` that returns the middle element, making sure odd/even sizes behave sensibly.
- [ ] Override `String#to_s` in a small script and observe the impact; revert afterward to avoid confusion.
- [ ] Implement a custom numeric helper (e.g., `5.minutes` returning seconds) and use it in a timer script.
- [ ] Explore refinements (`using ModuleName`) for safer, scoped patches.

Next: keep building in Flow Control & Collections, combining your augmented classes with loops and iterators, and then dive into Ruby Inheritance to organize related behavior.

#### Practice 1 - Adding Array#middle

**Goal:** Add a method to `Array` that returns the middle element, behaving sensibly for odd/even sizes.

#> ruby :practice

# TODO: Reopen Array and define #middle so that it returns the middle
# element for odd sizes and one of the two middle elements for even
# sizes (you can choose which).

```solution
class Array
  def middle
    return nil if empty?
    self[(size - 1) / 2]
  end
end

puts "odd middle: #{[1, 2, 3].middle}"
puts "even middle: #{[10, 20, 30, 40].middle}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('odd middle: 2') } && lines.any? { |l| l.include?('even middle: 20') }
```

#!


#### Practice 2 - Overriding String#to_s

**Goal:** Override `String#to_s` in a small script and observe the impact.

#> ruby :practice

# TODO: Print a small example that reopens String to override to_s and
# mention in a comment that this is only for experimentation.

```solution
class String
  alias_method :__original_to_s__, :to_s

  def to_s
    original = __original_to_s__
    "[string: #{original.inspect}]"
  end
end

value = "experimental"
puts value.to_s
puts value

class String
  alias_method :to_s, :__original_to_s__
  remove_method :__original_to_s__
end

puts "restored behavior: #{'demo'}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('[string: "experimental"]') } && lines.any? { |l| l.include?('restored behavior') }
```

#!


#### Practice 3 - Custom numeric helper

**Goal:** Implement a custom numeric helper (e.g., `5.minutes` returning seconds).

#> ruby :practice

# TODO: Reopen Integer and define minutes (and optionally seconds,
# hours) so that 5.minutes returns 300.

```solution
class Integer
  def minutes
    self * 60
  end
end

puts "5 minutes in seconds: #{5.minutes}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('5 minutes in seconds: 300') }
```

#!


#### Practice 4 - Exploring refinements

**Goal:** Explore refinements for safer, scoped patches.

#> ruby :practice

# TODO: Print a simple refinement that patches String inside a module
# and show how to activate it with using.

```solution
module StringRefinements
  refine String do
    def shout
      upcase + "!"
    end
  end
end

using StringRefinements
puts "hello".shout
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('HELLO!') }
```

#!
