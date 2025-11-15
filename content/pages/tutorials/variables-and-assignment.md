---
layout: tutorial
title: "Chapter 7 &ndash; Variables & Assignment"
permalink: /tutorials/variables-and-assignment/
difficulty: beginner
summary: Learn how Ruby creates variables, distinguishes barewords from method calls, and converts between strings and numbers using everyday scripts.
previous_tutorial:
  title: "Chapter 6: Fun with Strings"
  url: /tutorials/fun-with-strings/
next_tutorial:
  title: "Chapter 8: Scope"
  url: /tutorials/scope/
related_tutorials:
  - title: "Ruby Features"
    url: /tutorials/ruby-features/
  - title: "Numbers in Ruby"
    url: /tutorials/numbers-in-ruby/
---

> Adapted from Satish Talim's original RubyLearning lesson on variables, modernised for this Typophic site.

When you *assign* a value, Ruby creates the variable on the fly:

<pre class="language-ruby"><code class="language-ruby">
s = "Hello World!"
x = 10
</code></pre>

Ruby doesn't need a declaration keyword&mdash;the interpreter simply sees an assignment and allocates the variable.

### Barewords & local variables

A bareword is any unadorned identifier (letters, digits, underscores). Ruby interprets barewords in this order:

1. If an equals sign follows the bareword, it becomes a **local variable** receiving a value.
2. If it matches a reserved word, Ruby treats it as a **keyword** (e.g., `if`, `end`, `class`).
3. Otherwise, Ruby assumes it's a **method call** on the current object.

> Reference: <https://web.archive.org/web/20181219143329/http://alumnus.caltech.edu/~svhwan/prodScript/avoidBarewords.html> -- local variables and barewords share the same syntax, so prefer lowercase snake_case names and avoid Ruby keywords to keep intent clear.

<pre class="language-ruby"><code class="language-ruby">
puts greeting        # method call (will raise NameError if undefined)
answer = 42          # local variable assignment
class_name = &quot;User&quot;  # still a variable; keywords must be exact matches
</code></pre>

Because method calls and barewords share syntax, name collisions can be confusing. Stick to snake_case for locals, avoid Ruby keywords, and favour descriptive verbs for methods.

### Constants, locals, and conversions

Satish's `p004stringusage.rb` script still makes a great tour of assignments:

<pre class="language-ruby"><code class="language-ruby">
# frozen_string_literal: true

PI = 3.1416              # constant: name starts with uppercase
puts PI

my_string = "I love my city, Pune"
puts my_string

var1 = 5
var2 = "2"
puts var1 + var2.to_i    # convert string to integer
</code></pre>

Ruby ships with `.to_i`, `.to_f`, and `.to_s` on most core classes so you can convert as needed before combining values.

### Appending and here documents

Use the shovel operator `<<` to mutate a string in place:

<pre class="language-ruby"><code class="language-ruby">
message = "hello "
message << "world.\nI love this world..."
puts message
</code></pre>

For multi-line strings, reach for a heredoc:

<pre class="language-ruby"><code class="language-ruby">
story = &lt;&lt; END_STR
 This is the string And a second line
END_STR

puts story
</code></pre>

The line containing `END_STR` must be flush-left and match the opening identifier exactly.

### Messages, receivers, and dots

Method calls read as "send this **message** to that **receiver**." The dot connects the two:

<pre class="language-ruby"><code class="language-ruby">
x = "200.0".to_f
</code></pre>

Here the string `"200.0"` is the receiver and `to_f` is the message. Ruby evaluates the expression on the left of the dot first, then calls the method named on the right.

### Practice checklist

- [ ] Write a script that assigns the same bareword both as a local (`status = "new"`) and as a method (`def status; "ok"; end`) to observe the precedence rules.
- [ ] Recreate `p004stringusage.rb` and extend it with `.to_s` and `.to_f` examples.
- [ ] Append to a string with `<<` and compare the result to concatenation with `+`.
- [ ] Define a heredoc that includes interpolation and confirm it respects the surrounding quotation style (`<<~` for indentation stripping is handy).

Next: put these variables to work while branching through Flow Control & Collections.
