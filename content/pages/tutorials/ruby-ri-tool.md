---
layout: tutorial
title: "Chapter 13 &ndash; Ruby `ri` Tool"
permalink: /courses/ruby-basics/ruby-ri-tool/
difficulty: beginner
summary: Use Ruby's built-in `ri` and `rdoc` tools to browse documentation offline when the web isn't handy.
previous_tutorial:
  title: "Chapter 12: Writing Your Own Ruby Methods"
  url: /courses/ruby-basics/writing-own-ruby-methods/
next_tutorial:
  title: "Chapter 14: More on Strings"
  url: /courses/ruby-basics/more-on-strings/
related_tutorials:
  - title: "Ruby Features"
    url: /courses/ruby-basics/ruby-features/
  - title: "Methods & blocks"
    url: /courses/ruby-basics/methods-and-blocks/
---

> Adapted from Satish Talim's primer on `ri` and `RDoc`.

Fast internet isn't always available. Ruby ships documentation tools so you can stay productive offline:

- `ri` (Ruby Index) lets you look up classes, modules, and methods from the command line.
- `RDoc` extracts documentation comments from Ruby/C source files and formats them as HTML, Markdown, or `ri` data.

### Viewing docs with `ri`

Run `ri` followed by a constant or method name:

```bash
ri Array
ri Array.sort
ri Hash#each
ri Math::sqrt
```

Rules of thumb:

- Separate class or module names from instance methods with `#` (`String#upcase`).
- Use `::` for class methods (`Math::sqrt`).
- If you provide only a method name (`ri length`) and multiple classes define it, `ri` lists all matches.

`ri` displays formatted output generated from the same RDoc data that powers Ruby's online API docs.

### Generating docs with `rdoc`

Add structured comments to your Ruby or C files using RDoc markup, then run:

```bash
rdoc
```

By default, RDoc scans the current directory, collects comments, and writes HTML plus data files that `ri` can read. You can host the HTML or keep the `.ri` files locally for offline lookups.

Helpful references:

- <http://www.caliban.org/ruby/rubyguide.shtml#ri>
- <http://en.wikipedia.org/wiki/RDoc>
- <https://github.com/rdoc/rdoc>

### Practice checklist

- [ ] Run `ri String#split` and `ri Enumerable#map` to inspect their signatures.
- [ ] Document a small Ruby file with RDoc-style comments and generate HTML using `rdoc`.
- [ ] Explore class vs instance method lookups with `ri Math::cos` and `ri Math#cos` to see the difference.
- [ ] Cache the RDoc output for your project so you can browse it without internet access.

Next: armed with offline docs, continue into Flow Control & Collections to keep building Ruby fluency.

#### Practice 1 - Using ri for core methods

**Goal:** Show how you would run `ri` for common methods like `String#split` and `Enumerable#map`.

#> ruby :practice

# TODO: Print the ri invocations you would use to inspect String#split
# and Enumerable#map.

```solution
puts "ri String#split"
puts "ri Enumerable#map"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('ri String#split') } && lines.any? { |l| l.include?('ri Enumerable#map') }
```

#!


#### Practice 2 - RDoc comments and HTML generation

**Goal:** Document a Ruby file with RDoc-style comments and generate HTML with `rdoc`.

#> ruby :practice

# TODO: Print the rdoc command you would run to generate HTML docs for
# your project.

```solution
puts "rdoc -o doc ."
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('rdoc') }
```

#!


#### Practice 3 - Class vs instance method lookups

**Goal:** Explore `ri Math::cos` vs `ri Math#cos` to see class vs instance method lookups.

#> ruby :practice

# TODO: Print the two ri commands and a short note about what they
# mean.

```solution
puts "ri Math::cos  # class method"
puts "ri Math#cos   # instance method (for completeness)"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('Math::cos') } && lines.any? { |l| l.include?('Math#cos') }
```

#!


#### Practice 4 - Caching docs offline

**Goal:** Cache RDoc output so you can browse docs without internet access.

#> ruby :practice

# TODO: Print a short explanation of how generating HTML with rdoc
# gives you offline docs.

```solution
def cache_docs(output_dir = "doc")
  command = "rdoc -o #{output_dir} ."
  puts "Run: #{command}"
  puts "This caches HTML + ri data locally so you can browse offline docs later."
end

cache_docs
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('rdoc -o') } && lines.any? { |l| l.downcase.include?('offline docs') }
```

#!
