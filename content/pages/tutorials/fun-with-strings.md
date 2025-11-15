---
layout: tutorial
title: "Chapter 6 &ndash; Fun with Strings"
permalink: /tutorials/fun-with-strings/
difficulty: beginner
summary: Explore Ruby's flexible string literals, concatenation tricks, interpolation, and shell-friendly backticks before moving on to control flow.
previous_tutorial:
  title: "Chapter 5: Numbers in Ruby"
  url: /tutorials/numbers-in-ruby/
next_tutorial:
  title: "Chapter 7: Variables & Assignment"
  url: /tutorials/variables-and-assignment/
related_tutorials:
  - title: "Ruby Features"
    url: /tutorials/ruby-features/
  - title: "Flow control & collections"
    url: /tutorials/flow-control-collections/
---

> Adapted from Satish Talim's "Fun with Strings" lesson on RubyLearning, refreshed with modern Ruby notes.

Strings are sequences of characters surrounded by quotes. Ruby treats both single (`'`) and double (`"`) quotes as literal delimiters, and even the empty string (`''`) is a real object you can pass around.

### Warm up with a string script

Here's a modernised take on `p003rubystrings.rb`, highlighting concatenation, escaping, repetition, and constants:

<pre class="language-ruby"><code class="language-ruby">
# frozen_string_literal: true

puts "Hello World"
puts 'Hello World'             # same result, but no interpolation
puts 'I like' + ' Ruby'        # concatenation
puts 'Hello ' * 3              # repetition
puts 'It\s my Ruby'           # escape quotes

PI = 3.1416
puts PI
</code></pre>

Key takeaways:

- `puts` converts non-string objects with `to_s` before printing.
- Literal strings are mutable by default. Freeze them globally with `# frozen_string_literal: true` and unfreeze selectively via `+`prefix or `.dup`.
- Double-quoted strings support interpolation (`"Hi #{name}"`) and backslash escape sequences; single quotes keep content literal except for `\\` and `\'`.

### Command substitution with backticks

Backticks run shell commands and return their output as a string. The result still flows through Ruby, so you can print it, split it, or test it.

<pre class="language-ruby"><code class="language-ruby">
puts `ls`   # macOS/Linux: directory listing
puts `dir`  # Windows: directory listing
</code></pre>

Ruby also exposes `Kernel#system` when you simply need to execute a command and check success:

<pre class="language-ruby"><code class="language-ruby">
if system("tar xzf data.tgz")
  puts "Archive extracted"
else
  warn "Extraction failed"
end
</code></pre>

`system` returns `true` when the command exits successfully, `false` when it runs but fails, and `nil` if the command is missing.

### Practice checklist

- [ ] Recreate the sample script and add interpolation (`"Hello #{ENV['USER']}"`) plus concatenation to see both approaches.
- [ ] Freeze string literals at the top of a file and experiment with `+` and `.dup` to control mutability.
- [ ] Capture the output of `` `ruby -v` `` into a variable and parse the version number.
- [ ] Use `system` to run a harmless command (like `echo Done`) and branch on the return value.

#### Try it in the browser

<p><strong>Challenge:</strong> Write a short Ruby script that prints a greeting twice – once using interpolation and once using concatenation. When your output looks right, click “Check” to mark this practice as complete.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/fun-with-strings"
     data-expected-substring="Hello"><code class="language-ruby">
# Write your Ruby code here.
# Example goal (feel free to tweak):
#   Hello Alice
#   Hello Bob
#
# Use interpolation for one line and concatenation for the other.

</code></pre>
<div class="practice-feedback" data-practice-chapter="rl:chapter:/tutorials/fun-with-strings"></div>

Next up: apply what you know about numbers and strings while branching through Flow Control & Collections.
