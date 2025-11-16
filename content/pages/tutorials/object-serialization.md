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

#### Practice 1 - Sketching Marshal dump/load

<p><strong>Goal:</strong> Describe how you would serialize a custom class instance to disk and load it back.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/object-serialization"
     data-practice-index="0"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('Marshal.dump') } && lines.any? { |l| l.include?('Marshal.load') }"><code class="language-ruby">
# TODO: Print a short example showing Marshal.dump and Marshal.load
# used with a custom class instance and a file.
</code></pre>
<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/object-serialization"
     data-practice-index="0"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/object-serialization:0">
puts "File.open('user.dump', 'wb') { |f| Marshal.dump(user, f) }"
puts "user = File.open('user.dump', 'rb') { |f| Marshal.load(f) }"
</script>

#### Practice 2 - Rescuing Marshal TypeError

<p><strong>Goal:</strong> Attempt to marshal a proc and rescue the `TypeError`.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/object-serialization"
     data-practice-index="1"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('TypeError') }"><code class="language-ruby">
# TODO: Print a snippet that shows attempting to Marshal.dump a proc
# and rescuing TypeError with a friendly message.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/object-serialization"
     data-practice-index="1"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/object-serialization:1">
puts "begin"
puts "  Marshal.dump(-> { puts 'hi' })"
puts "rescue TypeError"
puts "  puts 'Cannot marshal procs'"
puts "end"
</script>

#### Practice 3 - Using StringIO for in-memory caching

<p><strong>Goal:</strong> Combine `Marshal.dump` with `StringIO` for in-memory caching.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/object-serialization"
     data-practice-index="2"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('StringIO') }"><code class="language-ruby">
# TODO: Print an example using StringIO.new as an in-memory buffer for
# Marshal.dump and Marshal.load.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/object-serialization"
     data-practice-index="2"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/object-serialization:2">
puts "buffer = StringIO.new"
puts "Marshal.dump(obj, buffer)"
puts "buffer.rewind"
puts "copy = Marshal.load(buffer)"
</script>

#### Practice 4 - Logging serialization failures

<p><strong>Goal:</strong> Wrap dump/load in `begin`/`rescue` and log failures.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/object-serialization"
     data-practice-index="3"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('logger') } && lines.any? { |l| l.include?('rescue') }"><code class="language-ruby">
# TODO: Print a short example that shows using Logger inside
# begin/rescue around serialization calls.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/object-serialization"
     data-practice-index="3"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/object-serialization:3">
puts "begin"
puts "  Marshal.dump(config, File.open('config.dump', 'wb'))"
puts "rescue => e"
puts "  logger.error(\"Failed to serialize config: \#{e.message}\")"
puts "end"
</script>
