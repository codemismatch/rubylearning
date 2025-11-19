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

<pre class="language-ruby" data-executable="true"><code class="language-ruby">
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
</code></pre>

- `size` and `length` return the element count.
- `first`, `last`, and `sort` provide quick helpers.
- Accessing beyond the ends returns `nil` rather than raising.

### Iteration with blocks

`Array#each` and friends rely on blocks:

<pre class="language-ruby" data-executable="true"><code class="language-ruby">
locations = [&quot;Pune&quot;, &quot;Mumbai&quot;, &quot;Bangalore&quot;]

locations.each do |loc|
  puts &quot;I love #{loc}!&quot;
  puts &quot;Don&#39;t you?&quot;
end

locations.delete(&quot;Mumbai&quot;)
</code></pre>

Thanks to blocks, you rarely need manual index counters.

### Methods returning arrays

Methods can return multiple values; Ruby wraps them in an array automatically:

<pre class="language-ruby" data-executable="true"><code class="language-ruby">
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
</code></pre>

### Parallel assignment & splats

<pre class="language-ruby" data-executable="true"><code class="language-ruby">
a = 1, 2, 3, 4   #=&gt; [1, 2, 3, 4]
a, b = 1, 2, 3, 4 # a=1, b=2 (remaining values ignored)
c, = 1, 2, 3, 4   # trailing comma lets you grab the first item only
</code></pre>

The splat (`*`) packs or unpacks arrays when you need flexible argument counts.

### ENV and ARGV helpers

- `ENV` behaves like a hash of environment variables and is enumerable:

  <pre class="language-ruby" data-executable="true"><code class="language-ruby">
ENV.each { |k, v| puts &quot;#{k}: #{v}&quot; }
ENV[&quot;course&quot;] = &quot;FORPC101&quot;
puts ENV[&quot;course&quot;]
</code></pre>

- Ruby reads certain environment variables when it starts, so updates you make later only affect the current process and any child processes you spawn. Setting a value to `nil` (Ruby 1.9+) removes the variable entirely.

- `ARGV` stores command-line arguments. Access with indexes (`ARGV[0]`) or parse with libraries such as `GetoptLong`:

  <pre class="language-ruby" data-executable="true"><code class="language-ruby">
require &quot;getoptlong&quot;

opts = GetoptLong.new(
[&quot;--hostname&quot;, &quot;-h&quot;, GetoptLong::REQUIRED_ARGUMENT],
[&quot;--port&quot;, &quot;-n&quot;, GetoptLong::REQUIRED_ARGUMENT],
[&quot;--username&quot;, &quot;-u&quot;, GetoptLong::REQUIRED_ARGUMENT],
[&quot;--pass&quot;, &quot;-p&quot;, GetoptLong::REQUIRED_ARGUMENT]
)

host = port = user = pass = nil
opts.each do |opt, arg|
  case opt
  when &quot;--hostname&quot; then host = arg
  when &quot;--port&quot;     then port = arg
  when &quot;--username&quot; then user = arg
  when &quot;--pass&quot;     then pass = arg
  end
end
</code></pre>

`require` pulls in stdlib helpers (and later, gems); here it exposes `GetoptLong`. We'll dive deeper into `require` soon.

### Coercing values to arrays

`Array(obj)` attempts to wrap or copy the value:

<pre class="language-ruby" data-executable="true"><code class="language-ruby">
Array(&quot;hello&quot;).class  #=&gt; Array
Array(&quot;hello\nworld&quot;) #=&gt; [&quot;hello\nworld&quot;]
[1,2,3,4].class.ancestors #=&gt; [Array, Enumerable, Object, Kernel, BasicObject]
</code></pre>

### Practice checklist

- [ ] Recreate `p018arrays.rb`, then add `push`, `pop`, and `shift` calls to see how the array mutates.
- [ ] Write a method that returns multiple values and capture them via parallel assignment.
- [ ] Iterate over `ENV` to print a subset of variables relevant to your setup.
- [ ] Parse fake CLI arguments with `GetoptLong` (or Ruby's newer `OptionParser`) and feed them into a script.
- [ ] Use `Array()` to wrap non-array objects and inspect `Array.ancestors` to understand its inheritance chain.

#### Practice 1 - Experimenting with array mutation

<p><strong>Goal:</strong> Recreate an array script and add `push`, `pop`, and `shift` calls to observe mutations.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-arrays"
     data-practice-index="0"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('after push') } && lines.any? { |l| l.downcase.include?('after pop') }"><code class="language-ruby">
# TODO: Create an array, then call push, pop, and shift on it,
# printing the array after each operation so you can see how it changes.
# Hint:
#   - Use puts with Array#inspect so the structure is visible.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-arrays"
     data-practice-index="0"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-arrays:0">
nums = [1, 2, 3]
puts "start:       #{nums.inspect}"

nums.push(4)
puts "after push:  #{nums.inspect}"

nums.pop
puts "after pop:   #{nums.inspect}"

nums.shift
puts "after shift: #{nums.inspect}"
</script>

#### Practice 2 - Parallel assignment with multiple return values

<p><strong>Goal:</strong> Write a method that returns multiple values and capture them with parallel assignment.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-arrays"
     data-practice-index="1"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.match?(/sum:/i) } && lines.any? { |l| l.match?(/average:/i) }"><code class="language-ruby">
# TODO: Define a method that returns multiple values (e.g., sum and
# average) and capture them with parallel assignment.
# Hint:
#   - Return an array from the method, then unpack it with
#     multiple variables on the left-hand side.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-arrays"
     data-practice-index="1"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-arrays:1">
def stats(nums)
  sum = nums.sum
  avg = sum.to_f / nums.size
  [sum, avg]
end

numbers = [2, 4, 6, 8]
sum, average = stats(numbers)

puts "sum: #{sum}"
puts "average: #{average}"
</script>

#### Practice 3 - Inspecting selected environment variables

<p><strong>Goal:</strong> Iterate over `ENV` and print a subset of variables relevant to your setup.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-arrays"
     data-practice-index="2"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.match?(/env/i) } || lines.size >= 1"><code class="language-ruby">
# TODO: Loop over ENV and print only a few variables that are
# interesting on your system (e.g., PATH, HOME).
# Hint:
#   - Use ENV.each or ENV.select with a list of keys.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-arrays"
     data-practice-index="2"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-arrays:2">
interesting = %w[PATH HOME SHELL]

interesting.each do |key|
  value = ENV[key]
  puts "#{key}=#{value.inspect}"
end
</script>

#### Practice 4 - Parsing fake CLI arguments

<p><strong>Goal:</strong> Parse fake CLI arguments and feed them into a script.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-arrays"
     data-practice-index="3"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('host') } && lines.any? { |l| l.downcase.include?('port') }"><code class="language-ruby">
# TODO: Simulate command-line arguments in an array and parse them
# into variables such as host and port.
# Hint:
#   - You can ignore GetoptLong and OptionParser here and just
#     iterate over an array of flags/values.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-arrays"
     data-practice-index="3"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-arrays:3">
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
</script>

#### Practice 5 - Using Array() and inspecting ancestors

<p><strong>Goal:</strong> Use `Array()` to wrap non-array objects and inspect `Array.ancestors`.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-arrays"
     data-practice-index="4"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('ancestors') }"><code class="language-ruby">
# TODO: Call Array() on a few different values and print the results,
# then print Array.ancestors to see where Array fits into Ruby's class
# hierarchy.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-arrays"
     data-practice-index="4"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-arrays:4">
puts "Array('hello')      => #{Array('hello').inspect}"
puts "Array(1..3)         => #{Array(1..3).inspect}"
puts "Array([:a, :b, :c]) => #{Array([:a, :b, :c]).inspect}"

puts "Array ancestors: #{Array.ancestors.inspect}"
</script>

Next: armed with arrays and blocks, jump into Flow Control & Collections to combine loops, iterators, and data structures.
