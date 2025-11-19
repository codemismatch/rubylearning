---
layout: tutorial
title: "Chapter 4 &ndash; Ruby Features"
permalink: /tutorials/ruby-features/
difficulty: beginner
summary: Get familiar with the language traits that shape every Ruby program, from free-form syntax to keywords and multi-line comments.
previous_tutorial:
  title: "Chapter 3: First Ruby Program"
  url: /tutorials/first-ruby-program/
next_tutorial:
  title: "Chapter 5: Numbers in Ruby"
  url: /tutorials/numbers-in-ruby/
related_tutorials:
  - title: "Flow control & collections"
    url: /tutorials/flow-control-collections/
  - title: "Ruby resources"
    url: /pages/resources/
---

> Adapted from Satish Talim's original RubyLearning course notes, refreshed for the modern Typophic-powered site.

Before diving into control flow and collections, it helps to know how Ruby thinks about structure, whitespace, and reserved words. Keep these features in mind as you experiment in IRB or inside scripts.

### Free-form layout

Ruby does not force code to start in a specific column. Feel free to indent to match nested blocks or align related values. Readability still matters, so stick to two-space indentation in this project.

<pre class="language-ruby"><code class="language-ruby">
message =
if Time.now.hour &lt; 12
  &quot;Morning!&quot;
else
  &quot;Later today!&quot;
end

puts message
</code></pre>

### Case sensitivity

Identifiers are case-sensitive: `user_name`, `UserName`, and `USERNAME` are three separate identifiers. Reserved words such as `end` must be lowercase; `END` is treated as a constant and will raise an error if it is undefined.

### Comments

Use `#` for inline comments--Ruby ignores everything to the end of the line:

<pre class="language-ruby"><code class="language-ruby">
total = price * 1.18 # add GST
</code></pre>

For longer notes, Ruby also supports `=begin` / `=end` blocks. They must start at column 0:

<pre class="language-ruby"><code class="language-ruby">
=begin
The parser skips every line between =begin and =end.
Helpful for quick docs or temporarily disabling code.
=end
</code></pre>

### Statement delimiters

Line endings usually delimit statements, so semi-colons are optional. Add one only when you truly need multiple statements on a single line:

<pre class="language-ruby"><code class="language-ruby">
puts &quot;Ready?&quot;; puts &quot;Go!&quot;
</code></pre>

A trailing backslash (`\`) tells Ruby the statement continues on the next line, which can be useful when splitting long expressions:

<pre class="language-ruby"><code class="language-ruby">
book_title = &quot;Ruby &quot; \
&quot;Learning&quot;
</code></pre>

### Keywords and truthiness

Ruby reserves about 40 keywords (e.g., `if`, `class`, `end`, `yield`). Avoid using them as variable names even if Ruby lets you prefix them with `@`, `@@`, or `$`. When checking truthiness, remember that *only* `false` and `nil` are falsey--`0`, empty strings, and empty collections all evaluate as true.

<pre class="language-ruby"><code class="language-ruby">
def logged_in?(token)
  !!token # converts anything except nil/false to true
end
</code></pre>

### Built-in documentation

Bookmark [`ruby-doc.org`](https://ruby-doc.org/) for the full core and standard-library docs, plus the [keywords reference](https://ruby-doc.org/core/doc/keywords_rdoc.html). Cheat sheets such as [cheat.errtheblog.com](http://cheat.errtheblog.com/) are great for quick reminders while you learn.

### Practice checklist

- [ ] Reformat a snippet from the previous chapter using Ruby's free-form layout rules.
- [ ] Add inline and block comments to `first_program.rb` explaining what each section does.
- [ ] Open IRB and confirm that `0`, `""`, and `[]` are all truthy (`!!value` returns `true`).
- [ ] Scan the keywords reference and note any that are new to you.

Ready to put these conventions to use? Continue to the next chapter to practise flow control and iterate through collections.

#### Practice 1 - Reformatting with free-form layout

<p><strong>Goal:</strong> Reformat a multi-line snippet using Ruby's flexible layout rules.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-features"
     data-practice-index="0"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('Ready?') } && lines.any? { |l| l.include?('Go!') }"><code class="language-ruby">
# TODO: Rewrite a short snippet (like the Ready/Go example) using
# Ruby's free-form layout: line breaks and optional semicolons.
# Print at least two lines of output.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-features"
     data-practice-index="0"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-features:0">
puts "Ready?"
puts "Go!"
</script>

#### Practice 2 - Adding comments to a small script

<p><strong>Goal:</strong> Add inline and block-style comments explaining what each section of a tiny script does.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-features"
     data-practice-index="1"
     data-test="out = output.string; lines = out.lines.map(&:strip).reject(&:empty?); lines.size >= 2 && lines.any? { |l| l.include?('Hello') || l.include?('Result') }"><code class="language-ruby">
# TODO: Write a short Ruby snippet and annotate it with comments
# explaining each major step.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-features"
     data-practice-index="1"></div>

<script type="text/plain" data-practice-solution="rl:chapter:/tutorials/ruby-features:1"># Print a greeting
name = "Rubyist"
puts "Hello, #{name}"

# Compute a simple result
result = 1 + 2
puts "Result is #{result}"</script>

#### Practice 3 - Checking truthiness

<p><strong>Goal:</strong> Confirm that `0`, `""`, and `[]` are all truthy using `!!value`.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-features"
     data-practice-index="2"
     data-test="out = output.string; out.include?('0') && out.include?('true') && out.scan(/true/).size >= 3"><code class="language-ruby">
# TODO: For each of 0, \"\", and [], compute !!value and print the
# value and the result to show they are truthy.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-features"
     data-practice-index="2"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-features:2">
[[0, "0"], ["", "\"\""], [[], "[]"]].each do |value, label|
  puts "#{label}: #{!!value}"
end
</script>

#### Practice 4 - Noting new keywords

<p><strong>Goal:</strong> Scan the keywords reference and note any that are new to you (simulated here).</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-features"
     data-practice-index="3"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('new keyword') }"><code class="language-ruby">
# TODO: Pretend you've scanned the keywords reference and print a
# couple of keywords that are new or interesting, labelling them
# as such.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-features"
     data-practice-index="3"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-features:3">
puts "New keyword to me: __END__"
puts "New keyword to me: redo"
</script>
