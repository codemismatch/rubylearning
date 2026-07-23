---
layout: tutorial
title: "Chapter 23 &ndash; Ruby Regular Expressions"
permalink: /courses/ruby-basics/ruby-regular-expressions/
difficulty: intermediate
summary: Match and capture patterns using Ruby's built-in `Regexp` objects, from literal characters to wildcards and capture groups.
previous_tutorial:
  title: "Chapter 22: Read/Write Text Files"
  url: /courses/ruby-basics/read-write-files/
next_tutorial:
  title: "Chapter 24: Writing Our Own Class"
  url: /courses/ruby-basics/writing-our-own-class/
related_tutorials:
  - title: "Ruby Symbols"
    url: /courses/ruby-basics/ruby-symbols/
  - title: "Ruby Hashes"
    url: /courses/ruby-basics/ruby-hashes/
---

> Adapted from Satish Talim's regular expressions lesson.

Regular expressions (regexps) describe patterns of text. In Ruby they're first-class objects (`Regexp`) that you delimit with slashes (`/pattern/`) or `%r{pattern}` when slashes would be awkward.

### Getting started

Regular expressions are full-fledged objects, so you can reference or store them just like any other value:

```ruby-exec
pattern = /Pune|Ruby/
pattern.class          #=> Regexp
```

Both regexps and strings respond to `.match`. Successful matches return a `MatchData` object, while failures return `nil`. The `=~` operator instead yields the starting index (or `nil`):

```ruby-exec
m1 = /Ruby/.match("The future is Ruby")
puts m1.class           # MatchData

m2 = "The future is Ruby" =~ /Ruby/
puts m2                 # 14 (start index)

/a/.match("b")          # nil
```

### Literal characters and escaping

- Literal characters match themselves: `/a/` finds the letter "a".
- The `|` operator means "either/or": `/Pune|Ruby/`.
- Special characters (`^`, `$`, `.`, `?`, `+`, `*`, `(`, `)`, `[`, `]`, `{`, `}`, `|`, `/`, `\`) must be escaped with `\` when you want their literal meaning: `/\?/` matches a question mark.

### Wildcards and character classes

- `.` (dot) matches any character except newline.
- Character classes (`[]`) limit matches to specific sets or ranges:

```ruby-exec
/.ejected/          # matches "dejected", "rejected", "%ejected"
/[dr]ejected/       # matches "dejected" or "rejected"
/[a-z]/             # lowercase letter
/[A-Fa-f0-9]/       # hexadecimal digit
/[^A-Fa-f0-9]/      # anything that is NOT a hexadecimal digit
```

Ruby also provides shorthand escapes for common classes:

- `\d` / `\D` -> digit / non-digit
- `\w` / `\W` -> word character (letters, digits, underscore) / non-word
- `\s` / `\S` -> whitespace / non-whitespace

### Match results and capture groups

Parentheses capture portions of the match. The result is a `MatchData` object with useful helpers:

- `string` - original string
- `[0]` - entire match
- `[1]`, `[2]`, ... - captures
- `captures` - array of captures

```ruby-exec
# p064regexp.rb
string = "My phone number is (123) 555-1234."
phone_re = /\((\d{3})\)\s+(\d{3})-(\d{4})/
m = phone_re.match(string)

unless m
  puts "There was no match..."
  exit
end

puts "Original: #{m.string}"
puts "Entire match: #{m[0]}"
puts "Area code: #{m[1]}"
puts "Exchange:  #{m[2]}"
puts "Number:    #{m[3]}"
```

`MatchData` objects are truthy, so you can use them directly in conditionals, whereas `nil` (the failure case) behaves like false.

### Practice checklist

- [ ] Test `=~` with and without matches to see the index vs `nil`.
- [ ] Write a regexp that matches lowercase hex digits, then negate it with `[^...]`.
- [ ] Capture month/day/year from a date string using groups and print the captures.
- [ ] Experiment with `String#sub`/`gsub` to replace text using regexps.

Next: return to Flow Control & Collections to combine regex-based parsing with loops and data structures.

#### Practice 1 - =~ index vs nil

**Goal:** Test `=~` with and without matches to see an index vs `nil`.

#> ruby :practice

# TODO: Use =~ on a string where the pattern matches and one where it
# does not, and print the index and nil results.

```solution
match_index = "Ruby" =~ /Ruby/
no_match = "Ruby" =~ /Python/
puts "index: #{match_index.inspect}"
puts "no match: #{no_match.inspect}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('index') } && lines.any? { |l| l.downcase.include?('nil') }
```

#!


#### Practice 2 - Matching and negating hex digits

**Goal:** Write a regexp that matches lowercase hex digits, then negate it with `[^...]`.

#> ruby :practice

# TODO: Print two regexps: one that matches lowercase hex digits and
# one that matches any character that's not a lowercase hex digit.

```solution
hex_string = "af09z"
matches = hex_string.scan(/[a-f0-9]/)
non_matches = hex_string.scan(/[^a-f0-9]/)

puts "hex digits: #{matches.join}"
puts "non-hex digits: #{non_matches.join}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('hex digits:') } && lines.any? { |l| l.include?('non-hex digits:') }
```

#!


#### Practice 3 - Capturing date components

**Goal:** Capture month/day/year from a date string using groups and print the captures.

#> ruby :practice

# TODO: Use a regexp with capture groups on a date string like
# 2024-01-31 or 31/01/2024 and print the components with labels.

```solution
date = "2024-01-31"
if date =~ /(\d{4})-(\d{2})-(\d{2})/
  year, month, day = $1, $2, $3
  puts "year: #{year}, month: #{month}, day: #{day}"
end
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('month') } && lines.any? { |l| l.downcase.include?('year') }
```

#!


#### Practice 4 - sub and gsub replacements

**Goal:** Experiment with `String#sub` and `String#gsub` to replace text using regexps.

#> ruby :practice

# TODO: Print a before string, then show the results of sub and gsub
# for a simple pattern.

```solution
text = "Ruby Ruby Ruby"
puts "sub:  #{text.sub(/Ruby/, 'Rails')}"
puts "gsub: #{text.gsub(/Ruby/, 'Rails')}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('sub:') } && lines.any? { |l| l.downcase.include?('gsub:') }
```

#!
