---
layout: tutorial
title: "Chapter 17 &ndash; Ruby Arrays"
permalink: /tutorials/ruby-arrays/
difficulty: beginner
summary: Build and reshape Ruby arrays, iterate with blocks, tap environment/ARGV helpers, and leverage splats for parallel assignment.
previous_tutorial:
  title: "Chapter 16: Ruby Blocks"
  url: /tutorials/ruby-blocks/
next_tutorial:
  title: "Chapter 18: Ruby Ranges"
  url: /tutorials/ruby-ranges/
related_tutorials:
  - title: "Flow control & collections"
    url: /tutorials/flow-control-collections/
  - title: "Writing Your Own Ruby Methods"
    url: /tutorials/writing-own-ruby-methods/
---

> Adapted from Satish Talim's original arrays chapter, refreshed for Typophic.

Arrays are ordered, mutable lists. Every slot holds a reference to any object (numbers, strings, other arrays). Ruby indexes from `0`, and negative indexes count from the end (`-1` is the last element).

### Constructing and expanding arrays

```ruby-exec
# p018arrays.rb
var1 = []                # empty array
var2 = [5]
var3 = ["Hello", "Goodbye"]

flavour = "mango"
var4 = [80.5, flavour, [true, false]]

name = ["Satish", "Talim", "Ruby", "Java",]
puts name[4]             # nil (out of bounds)
name[4] = "Pune"         # extend array
name[5] = 4.33
name[6] = [1, 2, 3]
```

- `size` and `length` return the element count.
- `first`, `last`, and `sort` provide quick helpers.
- Accessing beyond the ends returns `nil` rather than raising.

### Iteration with blocks

`Array#each` and friends rely on blocks:

```ruby-exec
locations = ["Pune", "Mumbai", "Bangalore"]

locations.each do |loc|
  puts "I love #{loc}!"
  puts "Don't you?"
end

locations.delete("Mumbai")
```

Thanks to blocks, you rarely need manual index counters.

### Methods returning arrays

Methods can return multiple values; Ruby wraps them in an array automatically:

```ruby-exec
# p019mtdarry.rb
def mtdarry
  10.times do |num|
    square = num * num
    return num, square if num > 5
  end
end

num, square = mtdarry
puts num    # 6
puts square # 36
```

### Parallel assignment & splats

```ruby-exec
a = 1, 2, 3, 4   #=> [1, 2, 3, 4]
a, b = 1, 2, 3, 4 # a=1, b=2 (remaining values ignored)
c, = 1, 2, 3, 4   # trailing comma lets you grab the first item only
```

The splat (`*`) packs or unpacks arrays when you need flexible argument counts.

### ENV and ARGV helpers

- `ENV` behaves like a hash of environment variables and is enumerable:

  ```ruby-exec
ENV.each { |k, v| puts "#{k}: #{v}" }
ENV["course"] = "FORPC101"
puts ENV["course"]
```

- Ruby reads certain environment variables when it starts, so updates you make later only affect the current process and any child processes you spawn. Setting a value to `nil` (Ruby 1.9+) removes the variable entirely.

- `ARGV` stores command-line arguments. Access with indexes (`ARGV[0]`) or parse them manually before reaching for heavier libraries:

  ```ruby-exec
args = %w[--hostname example.com --port 443 --username demo --pass secret]

host = port = user = pass = nil

args.each_slice(2) do |flag, value|
  case flag
  when "--hostname" then host = value
  when "--port"     then port = value.to_i
  when "--username" then user = value
  when "--pass"     then pass = value
  end
end

puts "Connecting to #{host}:#{port} as #{user} (pass length: #{pass.size})"
```

When your scripts grow, reach for helpers such as `OptionParser` via `require` so you can support short/long flags, defaults, and help text automatically.

### Coercing values to arrays

`Array(obj)` attempts to wrap or copy the value:

```ruby-exec
Array("hello").class  #=> Array
Array("hello\nworld") #=> ["hello\nworld"]
[1,2,3,4].class.ancestors #=> [Array, Enumerable, Object, Kernel, BasicObject]
```

### Practice checklist

- [ ] Recreate `p018arrays.rb`, then add `push`, `pop`, and `shift` calls to see how the array mutates.
- [ ] Write a method that returns multiple values and capture them via parallel assignment.
- [ ] Iterate over `ENV` to print a subset of variables relevant to your setup.
- [ ] Parse fake CLI arguments with `GetoptLong` (or Ruby's newer `OptionParser`) and feed them into a script.
- [ ] Use `Array()` to wrap non-array objects and inspect `Array.ancestors` to understand its inheritance chain.

#### Practice 1 - Experimenting with array mutation

**Goal:** Recreate an array script and add `push`, `pop`, and `shift` calls to observe mutations.

#> ruby :practice

# TODO: Create an array, then call push, pop, and shift on it,
# printing the array after each operation so you can see how it changes.
# Hint:
#   - Use puts with Array#inspect so the structure is visible.

```solution
nums = [1, 2, 3]
puts "start:       #{nums.inspect}"

nums.push(4)
puts "after push:  #{nums.inspect}"

nums.pop
puts "after pop:   #{nums.inspect}"

nums.shift
puts "after shift: #{nums.inspect}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('after push') } && lines.any? { |l| l.downcase.include?('after pop') }
```

#!


#### Practice 2 - Parallel assignment with multiple return values

**Goal:** Write a method that returns multiple values and capture them with parallel assignment.

#> ruby :practice

# TODO: Define a method that returns multiple values (e.g., sum and
# average) and capture them with parallel assignment.
# Hint:
#   - Return an array from the method, then unpack it with
#     multiple variables on the left-hand side.

```solution
def stats(nums)
  sum = nums.sum
  avg = sum.to_f / nums.size
  [sum, avg]
end

numbers = [2, 4, 6, 8]
sum, average = stats(numbers)

puts "sum: #{sum}"
puts "average: #{average}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.match?(/sum:/i) } && lines.any? { |l| l.match?(/average:/i) }
```

#!


#### Practice 3 - Inspecting selected environment variables

**Goal:** Iterate over `ENV` and print a subset of variables relevant to your setup.

#> ruby :practice

# TODO: Loop over ENV and print only a few variables that are
# interesting on your system (e.g., PATH, HOME).
# Hint:
#   - Use ENV.each or ENV.select with a list of keys.

```solution
interesting = %w[PATH HOME SHELL]

interesting.each do |key|
  value = ENV[key]
  puts "#{key}=#{value.inspect}"
end
```

```test
out = output.string; lines = out.lines.map(&:strip).reject(&:empty?); %w[PATH HOME SHELL].any? { |key| lines.any? { |line| line.start_with?("#{key}=") } }
```

#!


#### Practice 4 - Parsing fake CLI arguments

**Goal:** Parse fake CLI arguments and feed them into a script.

#> ruby :practice

# TODO: Simulate command-line arguments in an array and parse them
# into variables such as host and port.
# Hint:
#   - You can ignore GetoptLong and OptionParser here and just
#     iterate over an array of flags/values.

```solution
args = %w[--host localhost --port 3000]

host = nil
port = nil

args.each_slice(2) do |flag, value|
  case flag
  when "--host" then host = value
  when "--port" then port = value.to_i
  end
end

puts "host: #{host}"
puts "port: #{port}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('host') } && lines.any? { |l| l.downcase.include?('port') }
```

#!


#### Practice 5 - Using Array() and inspecting ancestors

**Goal:** Use `Array()` to wrap non-array objects and inspect `Array.ancestors`.

#> ruby :practice

# TODO: Call Array() on a few different values and print the results,
# then print Array.ancestors to see where Array fits into Ruby's class
# hierarchy.

```solution
samples = ["hello", 1..3, [:a, :b, :c]]

samples.each do |value|
  wrapped = Array(value)
  puts "Array(#{value.inspect}) => #{wrapped.inspect}"
end

ancestors = Array.ancestors.map(&:name).join(" -> ")
puts "Array ancestors: #{ancestors}"
```

```test
out = output.string
lines = out.lines.map(&:strip)
has_wrapped = ["Array(\"hello\")", "Array(1..3)", "Array([:a, :b, :c])"].all? do |label|
  lines.any? { |line| line.start_with?(label) }
end
has_ancestors = lines.any? { |line| line.downcase.include?("ancestors") }
has_wrapped && has_ancestors
```

#!


Next: armed with arrays and blocks, jump into Flow Control & Collections to combine loops, iterators, and data structures.
