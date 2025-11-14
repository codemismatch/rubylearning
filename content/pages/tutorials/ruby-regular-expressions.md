---
layout: tutorial
title: "Chapter 23 &ndash; Ruby Regular Expressions"
permalink: /tutorials/ruby-regular-expressions/
difficulty: intermediate
summary: Match and capture patterns using Ruby’s built-in `Regexp` objects, from literal characters to wildcards and capture groups.
previous_tutorial:
  title: "Chapter 22: Read/Write Text Files"
  url: /tutorials/read-write-files/
next_tutorial:
  title: "Chapter 24: Writing Our Own Class"
  url: /tutorials/writing-our-own-class/
related_tutorials:
  - title: "Ruby Symbols"
    url: /tutorials/ruby-symbols/
  - title: "Ruby Hashes"
    url: /tutorials/ruby-hashes/
---

> Adapted from Satish Talim’s regular expressions lesson.

Regular expressions (regexps) describe patterns of text. In Ruby they’re first-class objects (`Regexp`) that you delimit with slashes (`/pattern/`) or `%r{pattern}` when slashes would be awkward.

### Getting started

Regular expressions are full-fledged objects, so you can reference or store them just like any other value:

<pre class="language-ruby"><code class="language-ruby">
pattern = /Pune|Ruby/
pattern.class          #=&gt; Regexp
</code></pre>

Both regexps and strings respond to `.match`. Successful matches return a `MatchData` object, while failures return `nil`. The `=~` operator instead yields the starting index (or `nil`):

<pre class="language-ruby"><code class="language-ruby">
m1 = /Ruby/.match("The future is Ruby")
puts m1.class           # MatchData

m2 = "The future is Ruby" =~ /Ruby/
puts m2                 # 14 (start index)

/a/.match("b")          # nil
</code></pre>

### Literal characters and escaping

- Literal characters match themselves: `/a/` finds the letter “a”.
- The `|` operator means “either/or”: `/Pune|Ruby/`.
- Special characters (`^`, `$`, `.`, `?`, `+`, `*`, `(`, `)`, `[`, `]`, `{`, `}`, `|`, `/`, `\`) must be escaped with `\` when you want their literal meaning: `/\?/` matches a question mark.

### Wildcards and character classes

- `.` (dot) matches any character except newline.
- Character classes (`[]`) limit matches to specific sets or ranges:

<pre class="language-ruby"><code class="language-ruby">
/.ejected/          # matches “dejected”, “rejected”, “%ejected”
/[dr]ejected/       # matches “dejected” or “rejected”
/[a-z]/             # lowercase letter
/[A-Fa-f0-9]/       # hexadecimal digit
/[^A-Fa-f0-9]/      # anything that is NOT a hexadecimal digit
</code></pre>

Ruby also provides shorthand escapes for common classes:

- `\d` / `\D` → digit / non-digit
- `\w` / `\W` → word character (letters, digits, underscore) / non-word
- `\s` / `\S` → whitespace / non-whitespace

### Match results and capture groups

Parentheses capture portions of the match. The result is a `MatchData` object with useful helpers:

- `string` – original string
- `[0]` – entire match
- `[1]`, `[2]`, … – captures
- `captures` – array of captures

<pre class="language-ruby"><code class="language-ruby">
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
</code></pre>

`MatchData` objects are truthy, so you can use them directly in conditionals, whereas `nil` (the failure case) behaves like false.

### Practice checklist

- [ ] Test `=~` with and without matches to see the index vs `nil`.
- [ ] Write a regexp that matches lowercase hex digits, then negate it with `[^...]`.
- [ ] Capture month/day/year from a date string using groups and print the captures.
- [ ] Experiment with `String#sub`/`gsub` to replace text using regexps.

Next: return to Flow Control & Collections to combine regex-based parsing with loops and data structures.
