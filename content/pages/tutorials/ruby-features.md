---
layout: tutorial
title: "Chapter 4 &ndash; Ruby Features"
permalink: /courses/ruby-basics/ruby-features/
difficulty: beginner
summary: Get familiar with the language traits that shape every Ruby program, from free-form syntax to keywords and multi-line comments.
previous_tutorial:
  title: "Chapter 3: First Ruby Program"
  url: /courses/ruby-basics/first-ruby-program/
next_tutorial:
  title: "Chapter 5: Numbers in Ruby"
  url: /courses/ruby-basics/numbers-in-ruby/
related_tutorials:
  - title: "Flow control & collections"
    url: /courses/ruby-basics/flow-control-collections/
  - title: "Ruby resources"
    url: /pages/resources/
date: 2025-11-14
---

> Adapted from Satish Talim's original RubyLearning course notes, refreshed for the modern Typophic-powered site.

Before diving into control flow and collections, it helps to know how Ruby thinks about structure, whitespace, and reserved words. Keep these features in mind as you experiment in IRB or inside scripts.

### Free-form layout

Ruby does not force code to start in a specific column. Feel free to indent to match nested blocks or align related values. Readability still matters, so stick to two-space indentation in this project.

```ruby-exec
message =
if Time.now.hour < 12
  "Morning!"
else
  "Later today!"
end

puts message
```

### Case sensitivity

Identifiers are case-sensitive: `user_name`, `UserName`, and `USERNAME` are three separate identifiers. Reserved words such as `end` must be lowercase; `END` is treated as a constant and will raise an error if it is undefined.

### Comments

Use `#` for inline comments--Ruby ignores everything to the end of the line:

```ruby-exec
price = 100
total = price * 1.18 # add GST
```

For longer notes, Ruby also supports `=begin` / `=end` blocks. They must start at column 0:

```ruby-exec
=begin
The parser skips every line between =begin and =end.
Helpful for quick docs or temporarily disabling code.
=end
```

### Statement delimiters

Line endings usually delimit statements, so semi-colons are optional. Add one only when you truly need multiple statements on a single line:

```ruby-exec
puts "Ready?"; puts "Go!"
```

A trailing backslash (`\`) tells Ruby the statement continues on the next line, which can be useful when splitting long expressions:

```ruby-exec
book_title = "Ruby " \
"Learning"
```

### Keywords and truthiness

Ruby reserves about 40 keywords (e.g., `if`, `class`, `end`, `yield`). Avoid using them as variable names even if Ruby lets you prefix them with `@`, `@@`, or `$`. When checking truthiness, remember that *only* `false` and `nil` are falsey--`0`, empty strings, and empty collections all evaluate as true.

```ruby-exec
def logged_in?(token)
  !!token # converts anything except nil/false to true
end
```

### Built-in documentation

Bookmark [`ruby-doc.org`](https://ruby-doc.org/) for the full core and standard-library docs, plus the [keywords reference](https://ruby-doc.org/core/doc/keywords_rdoc.html). Cheat sheets such as [cheat.errtheblog.com](http://cheat.errtheblog.com/) are great for quick reminders while you learn.

### Practice checklist

- [ ] Reformat a snippet from the previous chapter using Ruby's free-form layout rules.
- [ ] Add inline and block comments to `first_program.rb` explaining what each section does.
- [ ] Open IRB and confirm that `0`, `""`, and `[]` are all truthy (`!!value` returns `true`).
- [ ] Scan the keywords reference and note any that are new to you.

Ready to put these conventions to use? Continue to the next chapter to practise flow control and iterate through collections.

#### Practice 1 - Reformatting with free-form layout

**Goal:** Reformat a multi-line snippet using Ruby's flexible layout rules.

#> ruby :practice

# TODO: Rewrite a short snippet (like the Ready/Go example) using
# Ruby's free-form layout: line breaks and optional semicolons.
# Print at least two lines of output.

```solution
puts "Ready?"
puts "Go!"
```

```test
out = output.string; lines = out.lines.map(&:strip).reject(&:empty?); lines.any? { |l| l.include?('Ready?') } && lines.any? { |l| l.include?('Go!') } && lines.size >= 2
```

#!

#### Practice 2 - Adding comments to a small script

**Goal:** Add inline and block-style comments explaining what each section of a tiny script does.

#> ruby :practice

# TODO: Write a short Ruby snippet and annotate it with comments
# explaining each major step.

```solution
# Print a greeting
name = "Rubyist"
puts "Hello, #{name}"

# Compute a simple result
result = 1 + 2
puts "Result is #{result}"
```

```test
out = output.string; lines = out.lines.map(&:strip).reject(&:empty?); lines.size >= 2 && (lines.any? { |l| l.downcase.include?('hello') } || lines.any? { |l| l.downcase.include?('result') })
```

#!

#### Practice 3 - Checking truthiness

**Goal:** Confirm that `0`, `""`, and `[]` are all truthy using `!!value`.

#> ruby :practice

# TODO: For each of 0, "" (empty string), and [], compute !!value and print the
# value and the result to show they are truthy.

```solution
[[0, "0"], ["", "\"\""], [[], "[]"]].each do |value, label|
  puts "#{label}: #{!!value}"
end
```

```test
out = output.string; out.include?('0') && out.scan(/[\x22]/).size >= 2 && out.include?('[]') && out.scan(/true/).size >= 3
```

#!

#### Practice 4 - Noting new keywords

**Goal:** Scan the keywords reference and note any that are new to you (simulated here).

#> ruby :practice

# TODO: Pretend you've scanned the keywords reference and print a
# couple of keywords that are new or interesting, labelling them
# as such.

```solution
puts "New keyword to me: __END__"
puts "New keyword to me: redo"
```

```test
out = output.string; lines = out.lines.map(&:strip).reject(&:empty?); lines.any? { |l| l.downcase.include?('new keyword') || l.downcase.include?('keyword') } && lines.size >= 1
```

#!
