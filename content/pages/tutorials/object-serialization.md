---
layout: tutorial
title: "Chapter 39 &ndash; Object Serialization (Marshal)"
permalink: /tutorials/object-serialization/
difficulty: beginner
summary: Persist Ruby objects by dumping and loading them with the built-in `Marshal` module.
previous_tutorial:
  title: "Chapter 38: Mutable vs Immutable Objects"
  url: /tutorials/mutable-and-immutable-objects/
next_tutorial:
  title: "Chapter 40: Modules & Mixins"
  url: /tutorials/modules-and-mixins/
related_tutorials:
  - title: "Read/Write Text Files"
    url: /tutorials/read-write-files/
  - title: "Ruby Exceptions"
    url: /tutorials/ruby-exceptions/
---

> Adapted from Satish Talim's object serialization lesson.

Ruby's `Marshal` module converts objects to byte streams (serialization) and back (deserialization). Handy for caching, storing session data, or quick persistence.

### Dumping and loading

<pre class="language-ruby"><code class="language-ruby">
data = { name: "Satish", skills: %w[ruby rails] }

File.open("data.dump", "wb") do |file|
  Marshal.dump(data, file)
end

loaded = File.open("data.dump", "rb") { |file| Marshal.load(file) }
puts loaded == data  #=> true
</code></pre>

You can also dump to a string:

<pre class="language-ruby"><code class="language-ruby">
payload = Marshal.dump(data)
restored = Marshal.load(payload)
</code></pre>

### Unsupported objects

Some things can't be marshaled (e.g., procs, bindings, IO objects, singleton objects). Catch `TypeError` if you're unsure.

### Practice checklist

- [ ] Serialize a custom class instance to disk and load it back in another script.
- [ ] Attempt to marshal a proc and rescue the resulting `TypeError`.
- [ ] Combine `Marshal.dump` with `StringIO` for in-memory caching.
- [ ] Wrap dump/load in `begin/rescue` blocks and log failures.

Next: continue to Flow Control & Collections, now with simple persistence techniques under your belt.
