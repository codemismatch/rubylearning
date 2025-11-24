---
layout: tutorial
title: "Chapter 15 &ndash; Simple Constructs"
permalink: /tutorials/simple-constructs/
difficulty: beginner
summary: Get comfortable with Ruby's core control-flow tools--`if`, `elsif`, `unless`, loops, ternaries, `case`, and the truthiness rules around `nil`.
previous_tutorial:
  title: "Chapter 14: More on Strings"
  url: /tutorials/more-on-strings/
next_tutorial:
  title: "Chapter 16: Ruby Blocks"
  url: /tutorials/ruby-blocks/
related_tutorials:
  - title: "Flow control & collections"
    url: /tutorials/flow-control-collections/
  - title: "Ruby Names"
    url: /tutorials/ruby-names/
---

> Adapted from Satish Talim's "Simple Constructs" lesson.

Ruby keeps branching syntax lightweight. Parentheses on `if`/`while` are optional, and indentation follows the semantic blocks (`if ... end`).

### `if`, nested blocks, and `elsif`

```ruby-exec
# p014constructs.rb
var = 5

if var > 4
  puts "Variable is greater than 4"
  if var == 5
    puts "Nested if else possible"
  else
    puts "Too cool"
  end
else
  puts "Variable is not greater than 4"
end
```

`elsif` cleans up stacked `if`/`else` chains:

```ruby-exec
# p015elsifex.rb
puts "Hello, what's your name?"
STDOUT.flush
name = gets.chomp

if name == "Satish"
  puts "What a nice name!!"
elsif name == "Sunil"
  puts "Another nice name!"
end

# Logical OR combines checks on one line
puts "Hello again..."
if name == "Satish" || name == "Sunil"
  puts "Still a great name!"
end
```

Truthiness recap: only `false` and `nil` evaluate as false. `0` and empty strings are truthy.

### `unless` and loops

`unless` is the inverse of `if`:

```ruby-exec
unless ARGV.length == 2
  puts "Usage: program.rb 23 45"
  exit
end
```

`while` handles simple loops:

```ruby-exec
var = 0
while var < 10
  puts var
  var += 1
end
```

### Ternary operator (`?:`)

Use the ternary operator for compact conditional expressions:

```ruby-exec
age = 15
puts (13...19).include?(age) ? "teenager" : "not a teenager"

person = (13...19).include?(23) ? "teenager" : "not a teenager"
```

### Statement modifiers

When the body is a single expression, place the condition after the statement:

```ruby-exec
participants = 3_200
puts "Enrollments will now stop" if participants > 2_500

missing_args = ARGV.empty?
warn "Missing args" unless missing_args
```

### `case` expressions

`case` is Ruby's flexible multi-branch construct and always returns the last evaluated expression:

```ruby-exec
year = 2000
leap = case
when year % 400 == 0 then true
when year % 100 == 0 then false
else year % 4 == 0
end

puts leap #=> true
```

You can also supply a target (`case value`), but the conditionless style above keeps things flexible.

### `nil` vs `false`

Both values are falsy, but they are different objects with different classes and IDs:

```ruby-exec
puts nil.class    # NilClass
puts false.class  # FalseClass
puts nil.object_id    # 4
puts false.object_id  # 0
```

Remember: `nil` is a real object (`NilClass`) and responds to methods just like any other object.

### Practice checklist

- [ ] Rewrite an `if`/`else` tree using `elsif` and then with logical operators to reduce nesting.
- [ ] Use `unless` to validate command-line arguments, then swap it with `if` to see which reads better.
- [ ] Convert a small `if/else` assignment into a ternary expression and back.
- [ ] Build a `case` expression that categorizes numeric ranges (e.g., fizz/buzz or temperature bands).

#### Practice 1 - Refactoring nested conditionals

**Goal:** Rewrite a nested `if`/`else` tree using `elsif` or logical operators to reduce nesting.

#> ruby :practice

# TODO: Start from a nested conditional (e.g., age + country checks)
# and refactor it to use elsif or logical operators so it's easier to
# read.
# Hint:
#   - Print a message for the 'eligible' and 'not eligible' cases.

```solution
age = 20
country = "IN"

message = if age >= 18
  if country == "IN"
    "Eligible to vote"
  else
    "Must vote in your own country"
  end
else
  "Not eligible to vote"
end

puts message

country = "US"
age = 20

message = if age >= 18 && country == "IN"
  "Eligible to vote"
else
  "Not eligible to vote"
end

puts message
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.count { |l| l.downcase.include?('eligible') } >= 1 && lines.any? { |l| l.downcase.include?('not eligible') }
```

#!


#### Practice 2 - Using unless for guard clauses

**Goal:** Use `unless` to validate command-line arguments and compare readability with `if`.

#> ruby :practice

# TODO: Check ARGV for at least one argument, using `unless` to
# display a usage message when none are provided.
# Hint:
#   - After trying with unless, rewrite the same logic with if.
#   - Print a clear usage or error message.

```solution
unless ARGV.any?
  puts "Usage: ruby script.rb <name>"
end
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('usage') } || lines.any? { |l| l.downcase.include?('missing') }
```

#!


#### Practice 3 - Ternary expression vs if/else

**Goal:** Convert a small `if/else` assignment into a ternary expression and back.

#> ruby :practice

# TODO: Assign a status string based on a condition using an if/else
# block, then rewrite it as a ternary expression.
# Hint:
#   - Use something like status = condition ? 'ok' : 'error'
#   - Print the final status.

```solution
score = 75

status = if score >= 60
  "pass"
else
  "fail"
end

status = score >= 60 ? "pass" : "fail"

puts "Status: #{status}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.match?(/status:/i) }
```

#!


#### Practice 4 - Case expression for range categories

**Goal:** Build a `case` expression that categorizes numeric ranges.

#> ruby :practice

# TODO: Use a case expression to categorize a temperature into ranges
# such as 'cold', 'warm', and 'hot'.
# Hint:
#   - Choose a temperature value and print the category.

```solution
temp = 28

label = case temp
when -Float::INFINITY...10
  "cold"
when 10...25
  "mild"
else
  "hot"
end

puts "Temperature #{temp}°C feels #{label}"

temp = 18

label = case temp
when -Float::INFINITY...10
  "cold"
when 10...25
  "mild"
else
  "hot"
end

puts "Temperature #{temp}°C feels #{label}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.match?(/hot/i) } && lines.any? { |l| l.match?(/mild/i) }
```

#!


Next: dive deeper into Flow Control & Collections to combine these constructs with loops, arrays, and hashes.
