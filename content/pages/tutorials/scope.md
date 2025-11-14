---
layout: tutorial
title: "Chapter 8 &ndash; Scope"
permalink: /tutorials/scope/
difficulty: beginner
summary: Understand where your Ruby variables live, how global symbols behave, and why local scopes form around classes, modules, and methods.
previous_tutorial:
  title: "Chapter 7: Variables & Assignment"
  url: /tutorials/variables-and-assignment/
next_tutorial:
  title: "Chapter 9: Getting Input"
  url: /tutorials/getting-input/
related_tutorials:
  - title: "Variables & Assignment"
    url: /tutorials/variables-and-assignment/
  - title: "Ruby Features"
    url: /tutorials/ruby-features/
---

> Adapted from Satish Talim's “Scope” chapter on RubyLearning, updated with modern Ruby examples.

Scope describes where a variable is visible. Ruby keeps the rules straightforward: variable *prefixes* indicate intent, and structural keywords (`class`, `module`, `def`) carve out local bubbles.

### Global scope and `$globals`

Any identifier that starts with `$` is a **global variable**. It is accessible everywhere in your process and never goes out of scope.

<pre class="language-ruby"><code class="language-ruby">
$app_mode = &quot;demo&quot;

def banner
  &quot;Running in #{$app_mode} mode&quot;
end

puts banner           #=&gt; &quot;Running in demo mode&quot;
</code></pre>

Because global state is hard to reason about, most Rubyists limit themselves to the built-in globals Ruby provides automatically.

#### Handy built-in globals

- `$0` &mdash; The filename used to invoke the current program.
- `$:` &mdash; An array of directories Ruby searches when you `require` files.
- `$$` &mdash; The process ID of the current Ruby interpreter.

You can inspect them just like any other variable:

<pre class="language-ruby"><code class="language-ruby">
puts &quot;Running #{$0} (PID #{$$})&quot;
puts &quot;Load path has #{$:.size} entries&quot;
</code></pre>

### Local scope rules

Locals are far more common than globals. Ruby (MRI) follows three big rules:

1. The **top level** (outside any class/module/method) has its own scope.
2. Each `class` or `module` block introduces a new local scope. Nested definitions get their own scopes too.
3. Every `def` creates a brand-new scope. Locals from the outer scope are not automatically visible unless captured in a block or passed in.

<pre class="language-ruby"><code class="language-ruby">
message = &quot;outside&quot;

class ScopeDemo
  message = &quot;inside class&quot;

  def self.print_messages
    message = &quot;inside method&quot;
    puts message
  end
end

ScopeDemo.print_messages  # prints &quot;inside method&quot;
puts message              # prints &quot;outside&quot;
</code></pre>

Notice how each structural boundary protects its own copy of `message`.

### Blocks inherit, defs isolate

Blocks (`do..end`, `{}`) share their parent's local scope:

<pre class="language-ruby"><code class="language-ruby">
count = 0
3.times do
  count += 1
end
puts count #=&gt; 3
</code></pre>

Method definitions (`def`) always start fresh, so read/write outer locals via instance variables, accessors, or closures (e.g., lambdas) when needed.

### Practice checklist

- [ ] Print `$0`, `$$`, and the size of `$:` in a scratch script to see their values on your machine.
- [ ] Create nested `class`/`module` definitions and confirm each maintains its own `message` local.
- [ ] Compare a block's behaviour (which can increment an outer local) with a method definition (which cannot) using similar code.
- [ ] Refactor a small script to replace a global variable with an instance variable or dependency injection to reduce scope.

Next: Apply these scope rules as you branch and iterate inside Flow Control & Collections.
