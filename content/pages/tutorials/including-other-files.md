---
layout: tutorial
title: "Chapter 27 &ndash; Including Other Files"
permalink: /tutorials/including-other-files/
difficulty: beginner
summary: Share code across Ruby files with `require`, `load`, and `require_relative`, and understand how Ruby locates those files.
previous_tutorial:
  title: "Chapter 26: Ruby Procs & Lambdas"
  url: /tutorials/ruby-procs/
next_tutorial:
  title: "Chapter 28: Ruby Open Classes"
  url: /tutorials/ruby-open-classes/
related_tutorials:
  - title: "Ruby Hashes"
    url: /tutorials/ruby-hashes/
  - title: "Read/Write Text Files"
    url: /tutorials/read-write-files/
---

> Adapted from Satish Talim's "Including Other Files" lesson.

As your Ruby programs grow, you'll split code across files. Ruby provides three helpers:

- `require` - loads a file once, searching `$LOAD_PATH` (aliased as `$:`).
- `load` - forcibly reloads a file every time you call it.
- `require_relative` - loads a file relative to the current file's directory.

### `require`

Use `require` for gems, stdlib components, or project files that should load at most once per process.

<pre class="language-ruby" data-executable="true"><code class="language-ruby">
require &quot;json&quot;                 # stdlib
require &quot;pg&quot;                   # gem
require_relative &quot;lib/user&quot;    # project file (see below)
</code></pre>

`require` returns `true` when it loads a file, `false` when the file was already loaded, and raises `LoadError` if it can't find the file.

Ruby looks through each directory in `$LOAD_PATH` for the requested file. You can inspect or modify the path:

<pre class="language-ruby" data-executable="true"><code class="language-ruby">
puts $LOAD_PATH
$LOAD_PATH.unshift File.expand_path(&quot;../lib&quot;, __dir__)
</code></pre>

### `load`

`load "scripts/setup.rb"` reprocesses the file every time you call it. You can pass a second argument of `true` to wrap the loaded code in an anonymous module:

<pre class="language-ruby" data-executable="true"><code class="language-ruby">
load &quot;scripts/setup.rb&quot;, true
</code></pre>

This is handy for DSLs or when you need the latest version of a file during development.

### `require_relative`

For project-local files, `require_relative` resolves paths relative to the file containing the call:

<pre class="language-ruby" data-executable="true"><code class="language-ruby">
require_relative &quot;../models/user&quot;
</code></pre>

This avoids fiddling with `$LOAD_PATH` and keeps dependencies explicit.

### Splitting code across files

Legacy example: `abbrev.rb` might define methods, and `testabbrev.rb` can reuse them:

<pre class="language-ruby" data-executable="true"><code class="language-ruby">
# abbrev.rb
def short_name(full_name)
  full_name.split.first
end

# testabbrev.rb
require_relative &quot;abbrev&quot;
puts short_name(&quot;Satish Talim&quot;)
</code></pre>

### Practice checklist

- [ ] Create two files, define a helper in one, and `require_relative` it from the other.
- [ ] Modify `$LOAD_PATH` to include a `lib/` directory and require a file from there.
- [ ] Use `load` to execute a script twice and observe that any top-level code reruns.
- [ ] Rescue `LoadError` to provide a helpful message when an optional dependency is missing.

Next: return to Flow Control & Collections to keep building on these reusable building blocks.

#### Practice 1 - Thinking through require_relative

<p><strong>Goal:</strong> Describe how you would split code across two files and use `require_relative`.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/including-other-files"
     data-practice-index="0"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('require_relative') }"><code class="language-ruby">
# TODO: Print a tiny example that shows a helper defined in one file
# and required from another using require_relative.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/including-other-files"
     data-practice-index="0"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/including-other-files:0">
puts 'require_relative "helpers/string_helpers"'
puts 'include StringHelpers'
</script>

#### Practice 2 - $LOAD_PATH and lib

<p><strong>Goal:</strong> Show how you would modify `$LOAD_PATH` to include a `lib/` directory.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/including-other-files"
     data-practice-index="1"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('$LOAD_PATH') } && lines.any? { |l| l.include?('lib') }"><code class="language-ruby">
# TODO: Print a snippet that pushes 'lib' onto $LOAD_PATH and requires
# a file from there.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/including-other-files"
     data-practice-index="1"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/including-other-files:1">
puts "$LOAD_PATH.unshift(File.expand_path('lib', __dir__))"
puts "require 'my_library'"
</script>

#### Practice 3 - load and rerunning top-level code

<p><strong>Goal:</strong> Use `load` to execute a script twice and understand that top-level code reruns.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/including-other-files"
     data-practice-index="2"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.start_with?('load ') }"><code class="language-ruby">
# TODO: Print a short example that shows calling load twice on the
# same file.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/including-other-files"
     data-practice-index="2"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/including-other-files:2">
puts "load 'scripts/setup.rb'"
puts "load 'scripts/setup.rb' # runs again"
</script>

#### Practice 4 - Rescuing LoadError

<p><strong>Goal:</strong> Show how you would rescue `LoadError` for an optional dependency.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/including-other-files"
     data-practice-index="3"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('LoadError') } && lines.any? { |l| l.include?('require') }"><code class="language-ruby">
# TODO: Print a begin/rescue snippet that rescues LoadError around a
# require call and prints a friendly message.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/including-other-files"
     data-practice-index="3"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/including-other-files:3">
puts "begin"
puts "  require 'optional_gem'"
puts "rescue LoadError"
puts "  puts 'Install optional_gem for extra features'"
puts "end"
</script>
