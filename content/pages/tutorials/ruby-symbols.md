---
layout: tutorial
title: "Chapter 19 &ndash; Ruby Symbols"
permalink: /tutorials/ruby-symbols/
difficulty: beginner
summary: Learn when to reach for symbols instead of strings, why they're unique and memory-friendly, and how to convert between types.
previous_tutorial:
  title: "Chapter 18: Ruby Ranges"
  url: /tutorials/ruby-ranges/
next_tutorial:
  title: "Chapter 20: Ruby Hashes"
  url: /tutorials/ruby-hashes/
related_tutorials:
  - title: "Hashes"
    url: /tutorials/hashes/
  - title: "Ruby Names"
    url: /tutorials/ruby-names/
---

> Adapted from Satish Talim's Ruby Symbols lesson.

Symbols are lightweight, immutable identifiers prefixed with a colon (e.g., `:action`, `:line_items`). Think of the colon as saying "the thing named ...". Ruby auto-interns symbols so each unique spelling corresponds to exactly one object for the duration of the program.

### Strings vs symbols

- Strings carry content; multiple string literals with the same characters are distinct objects.
- Symbols represent identity; each unique symbol exists once in Ruby's symbol table.

Use strings when you care about the text itself, and symbols when you just need consistent names or keys.

```ruby-exec
# p039symbol.rb
puts "string".object_id
puts "string".object_id
puts :symbol.object_id
puts :symbol.object_id
```

The second string has a different `object_id`; the symbol doesn't.

### How Ruby uses symbols

Ruby automatically creates symbols for method names, class names, instance variables, etc. `Symbol.all_symbols` reveals the current symbol table, though you rarely need to inspect it.

Symbols are simple `Symbol` objects backed by an internal integer ID. Redefining a method or referencing the same identifier elsewhere reuses the existing symbol:

```ruby-exec
# p039xsymbol.rb
class Test
  puts :Test.object_id

  def test
    puts :test.object_id
    @test = 10
    puts :test.object_id
  end
end

Test.new.test
```

### Predicate-style flags

Symbols make expressive flags:

```ruby-exec
# p039xysymbol.rb
know_ruby = :yes

if know_ruby == :yes
  puts "You are a Rubyist"
else
  puts "Start learning Ruby"
end
```

Comparing strings works too, but every literal allocates a new object, while symbols do not.

### Converting between strings and symbols

```ruby-exec
"string".to_sym.class #=> Symbol
:symbol.to_s.class    #=> String
```

This is handy when bridging user input (strings) and internal identifiers (symbols).

### Symbols as hash keys

Symbols shine as hash keys because they're immutable and faster to compare. You'll see syntax like `{ name: "Satish", city: "Pune" }`, where `name:` is a symbol key (`:name`).

### Practice checklist

- [ ] Run `Symbol.all_symbols.size` before and after defining a new method to see the table grow.
- [ ] Rewrite a configuration hash using symbol keys instead of strings.
- [ ] Compare memory usage or `object_id` for repeated strings vs repeated symbols in IRB.
- [ ] Convert user-supplied strings to symbols with `.to_sym` (but validate before calling `send` to avoid security issues).

Next: build on these naming primitives as you dive deeper into Flow Control & Collections and the upcoming Hashes chapter.

#### Practice 1 - Symbol table growth

**Goal:** Observe `Symbol.all_symbols.size` before and after defining a new method.

#> ruby :practice

# TODO: Print the calls you would run in IRB to measure the symbol
# table size before and after defining a method.

```solution
puts "before = Symbol.all_symbols.size"
puts "def new_method; end"
puts "after = Symbol.all_symbols.size"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('Symbol.all_symbols.size') }
```

#!


#### Practice 2 - Rewriting config hashes with symbols

**Goal:** Rewrite a configuration hash using symbol keys instead of strings.

#> ruby :practice

# TODO: Print a before/after example of a hash that uses string keys
# and then symbol keys for configuration.

```solution
puts 'config_str = { "host" => "localhost", "port" => 3000 }'
puts 'config_sym = { host: "localhost", port: 3000 }'
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?(':host') } && lines.any? { |l| l.include?(':port') }
```

#!


#### Practice 3 - object_id for strings vs symbols

**Goal:** Compare `object_id` for repeated strings vs repeated symbols.

#> ruby :practice

# TODO: Print object_ids for repeated strings and symbols to show that
# strings allocate new objects but symbols do not.

```solution
puts '"hello".object_id  # string object_id'
puts '"hello".object_id  # different from previous'
puts ':hello.object_id   # symbol object_id (same each time)'
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('string object_id') } && lines.any? { |l| l.downcase.include?('symbol object_id') }
```

#!


#### Practice 4 - Safe to_sym usage

**Goal:** Convert user-supplied strings to symbols safely with `.to_sym`.

#> ruby :practice

# TODO: Print a snippet that validates a user-supplied string against
# a whitelist before calling to_sym and send.

```solution
puts "allowed = %w[name email]"
puts "if allowed.include?(input)"
puts "  key = input.to_sym"
puts "end"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('.to_sym') } && lines.any? { |l| l.downcase.include?('validate') }
```

#!

