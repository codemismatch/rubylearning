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

> Adapted from Satish Talim’s “Including Other Files” lesson.

As your Ruby programs grow, you’ll split code across files. Ruby provides three helpers:

- `require` – loads a file once, searching `$LOAD_PATH` (aliased as `$:`).
- `load` – forcibly reloads a file every time you call it.
- `require_relative` – loads a file relative to the current file’s directory.

### `require`

Use `require` for gems, stdlib components, or project files that should load at most once per process.

<pre class="language-ruby"><code class="language-ruby">
require &quot;json&quot;                 # stdlib
require &quot;pg&quot;                   # gem
require_relative &quot;lib/user&quot;    # project file (see below)
</code></pre>

`require` returns `true` when it loads a file, `false` when the file was already loaded, and raises `LoadError` if it can’t find the file.

Ruby looks through each directory in `$LOAD_PATH` for the requested file. You can inspect or modify the path:

<pre class="language-ruby"><code class="language-ruby">
puts $LOAD_PATH
$LOAD_PATH.unshift File.expand_path(&quot;../lib&quot;, __dir__)
</code></pre>

### `load`

`load "scripts/setup.rb"` reprocesses the file every time you call it. You can pass a second argument of `true` to wrap the loaded code in an anonymous module:

<pre class="language-ruby"><code class="language-ruby">
load &quot;scripts/setup.rb&quot;, true
</code></pre>

This is handy for DSLs or when you need the latest version of a file during development.

### `require_relative`

For project-local files, `require_relative` resolves paths relative to the file containing the call:

<pre class="language-ruby"><code class="language-ruby">
require_relative &quot;../models/user&quot;
</code></pre>

This avoids fiddling with `$LOAD_PATH` and keeps dependencies explicit.

### Splitting code across files

Legacy example: `abbrev.rb` might define methods, and `testabbrev.rb` can reuse them:

<pre class="language-ruby"><code class="language-ruby">
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
