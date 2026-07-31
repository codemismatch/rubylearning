---
layout: tutorial
title: "Chapter 18 &ndash; Ruby Ranges"
permalink: /courses/ruby-basics/ruby-ranges/
difficulty: beginner
summary: Use inclusive/exclusive ranges to model sequences, iterate efficiently, and perform interval tests with `===`.
previous_tutorial:
  title: "Chapter 17: Ruby Arrays"
  url: /courses/ruby-basics/ruby-arrays/
next_tutorial:
  title: "Chapter 19: Ruby Symbols"
  url: /courses/ruby-basics/ruby-symbols/
related_tutorials:
  - title: "Flow control & collections"
    url: /courses/ruby-basics/flow-control-collections/
  - title: "Simple Constructs"
    url: /courses/ruby-basics/simple-constructs/
date: 2025-11-14
---

> Adapted from Satish Talim's original ranges lesson.

Ranges represent sequences with a start, an end, and a way to produce successive values. They're light-weight objects that reference the boundary values rather than allocating every member up front.

### Inclusive vs exclusive ranges

- `..` (two dots) creates an inclusive range containing the high value.
- `...` (three dots) excludes the high value.

```ruby-exec
(1..5).to_a    #=> [1, 2, 3, 4, 5]
(1...5).to_a   #=> [1, 2, 3, 4]
```

Ranges aren't stored as arrays internally--`1..100_000` keeps just the endpoints--but you can convert one to an array with `to_a` when needed.

### Common helpers

```ruby-exec
# p021ranges.rb
digits = -1..9
puts digits.include?(5)          # true
puts digits.min                  # -1
puts digits.max                  # 9
puts digits.reject { |i| i < 5 } # [5, 6, 7, 8, 9]
```

Because ranges mix in `Enumerable`, you get iterators like `each`, `map`, `reject`, and friends out of the box.

### Interval testing with `===`

Ranges shine when checking if a value falls within a specific interval. Use the case-equality operator (`===`), which also powers `case` statements:

```ruby-exec
(1..10) === 5        # true
(1..10) === 15       # false
(1..10) === 3.14159  # true
("a".."j") === "c"   # true
("a".."j") === "z"   # false
```

Drop ranges directly into `case` expressions for readable branching:

```ruby-exec
grade = 87
label = case grade
when 90..100 then "A"
when 80...90 then "B"
else "Needs work"
end
```

### Practice checklist

- [ ] Convert `(1..10)` and `(1...10)` to arrays and compare the results.
- [ ] Use `include?`, `min`, and `max` on a negative-to-positive range.
- [ ] Write a method that accepts a range and yields only the even members via `select`.
- [ ] Build a `case` expression that classifies temperatures using range intervals.

Next: continue into Flow Control & Collections where ranges, arrays, and enumerators come together in loops and iterators.

#### Practice 1 - Inclusive vs exclusive ranges

**Goal:** Convert `(1..10)` and `(1...10)` to arrays and compare the results.

#> ruby :practice

# TODO: Print the arrays produced by (1..10).to_a and (1...10).to_a
# with clear labels.

```solution
puts "1..10  => #{(1..10).to_a.inspect}"
puts "1...10 => #{(1...10).to_a.inspect}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('1..10') } && lines.any? { |l| l.include?('1...10') }
```

#!


#### Practice 2 - include?, min, max on ranges

**Goal:** Use `include?`, `min`, and `max` on a negative-to-positive range.

#> ruby :practice

# TODO: Create a range from -5 to 5 and print whether it includes 0,
# along with its min and max.

```solution
range = -5..5
puts "include?(0): #{range.include?(0)}"
puts "min: #{range.min}, max: #{range.max}"
```

```test
out = output.string; lines = out.lines.map(&:strip); %w[include? min max].all? { |m| lines.any? { |l| l.include?(m) } }
```

#!


#### Practice 3 - Yielding even members from a range

**Goal:** Write a method that accepts a range and yields only the even members using `select`.

#> ruby :practice

# TODO: Print an example method that takes a range and returns only
# its even numbers with select.

```solution
def evens(range)
  range.select(&:even?)
end

result = evens(1..10)
puts "even numbers: #{result.inspect}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('even numbers') } && out.include?('2') && out.include?('10')
```

#!


#### Practice 4 - case with range intervals

**Goal:** Build a `case` expression that classifies temperatures using ranges.

#> ruby :practice

# TODO: Print a case expression that categorises a temperature as
# cold, mild, or hot using range intervals.

```solution
def classify_temperature(temp)
  case temp
  when -50...10 then "cold"
  when 10...25 then "mild"
  else "hot"
  end
end

puts "5°C -> #{classify_temperature(5)}"
puts "15°C -> #{classify_temperature(15)}"
puts "30°C -> #{classify_temperature(30)}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('cold') } && lines.any? { |l| l.include?('mild') } && lines.any? { |l| l.include?('hot') }
```

#!
