---
layout: tutorial
title: "Chapter 9 &ndash; Getting Input"
permalink: /tutorials/getting-input/
difficulty: beginner
summary: Read keyboard input with `gets`, tidy it up with `chomp`, and understand when to flush STDOUT for interactive prompts.
previous_tutorial:
  title: "Chapter 8: Scope"
  url: /tutorials/scope/
next_tutorial:
  title: "Chapter 10: Ruby Names"
  url: /tutorials/ruby-names/
related_tutorials:
  - title: "Variables & Assignment"
    url: /tutorials/variables-and-assignment/
  - title: "Ruby Features"
    url: /tutorials/ruby-features/
---

> Adapted from Satish Talim's original RubyLearning lesson on user input, refreshed for Typophic.

So far you've been printing output with `puts`. To make your scripts interactive you need to read input from the keyboard (standard input). Ruby ships the `gets` method for this and a companion `String#chomp` helper to trim trailing newlines.

### Sample prompt script

<pre class="language-ruby"><code class="language-ruby">
# p005methods.rb
# gets and chomp
puts "In which city do you stay?"
STDOUT.flush
city = gets.chomp
puts "The city is #{city}"
</code></pre>

What’s happening:

- `STDOUT` is the global constant for the program’s standard output stream.
- `STDOUT.flush` forces Ruby to push any buffered output to the console immediately, ensuring the prompt appears before `gets` blocks. You can skip this if you set `STDOUT.sync = true` once, which enables auto-flushing.
- `gets` reads a line from standard input (the keyboard) and returns it as a string including the trailing newline.
- `chomp` removes the trailing newline so string concatenation/interpolation behaves as expected.

### Input sources in Rails land

Rails apps rarely call `gets` because web requests provide parameters and data comes from databases. Still, understanding Ruby’s core IO helps when you write scripts, background jobs, or quick prototypes outside the request/response cycle.

### Practice checklist

- [ ] Modify the sample script to request both city and country, and print a combined sentence.
- [ ] Toggle `STDOUT.sync = true` at the top of your script and remove manual `flush` calls to see the effect.
- [ ] Capture numeric input (`gets.chomp.to_i`) and use it in a calculation.
- [ ] Experiment with piping data into your script (`echo "Pune" | ruby prompt.rb`) to see how standard input differs from keyboard typing.

Up next: move into Flow Control & Collections to react to the data you just gathered.
