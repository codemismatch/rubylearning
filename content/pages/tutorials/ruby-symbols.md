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

<pre class="language-ruby"><code class="language-ruby">
# p039symbol.rb
puts "string".object_id
puts "string".object_id
puts :symbol.object_id
puts :symbol.object_id
</code></pre>

The second string has a different `object_id`; the symbol doesn't.

### How Ruby uses symbols

Ruby automatically creates symbols for method names, class names, instance variables, etc. `Symbol.all_symbols` reveals the current symbol table, though you rarely need to inspect it.

Symbols are simple `Symbol` objects backed by an internal integer ID. Redefining a method or referencing the same identifier elsewhere reuses the existing symbol:

<pre class="language-ruby"><code class="language-ruby">
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
</code></pre>

### Predicate-style flags

Symbols make expressive flags:

<pre class="language-ruby"><code class="language-ruby">
# p039xysymbol.rb
know_ruby = :yes

if know_ruby == :yes
  puts "You are a Rubyist"
else
  puts "Start learning Ruby"
end
</code></pre>

Comparing strings works too, but every literal allocates a new object, while symbols do not.

### Converting between strings and symbols

<pre class="language-ruby"><code class="language-ruby">
&quot;string&quot;.to_sym.class #=&gt; Symbol
:symbol.to_s.class    #=&gt; String
</code></pre>

This is handy when bridging user input (strings) and internal identifiers (symbols).

### Symbols as hash keys

Symbols shine as hash keys because they're immutable and faster to compare. You'll see syntax like `{ name: "Satish", city: "Pune" }`, where `name:` is a symbol key (`:name`).

### Practice checklist

- [ ] Run `Symbol.all_symbols.size` before and after defining a new method to see the table grow.
- [ ] Rewrite a configuration hash using symbol keys instead of strings.
- [ ] Compare memory usage or `object_id` for repeated strings vs repeated symbols in IRB.
- [ ] Convert user-supplied strings to symbols with `.to_sym` (but validate before calling `send` to avoid security issues).

Next: build on these naming primitives as you dive deeper into Flow Control & Collections and the upcoming Hashes chapter.
