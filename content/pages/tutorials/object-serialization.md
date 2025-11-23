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

```ruby-exec
data = { name: "Satish", skills: %w[ruby rails] }

File.open("data.dump", "wb") do |file|
  Marshal.dump(data, file)
end

loaded = File.open("data.dump", "rb") { |file| Marshal.load(file) }
puts loaded == data  #=> true
```

You can also dump to a string:

```ruby-exec
payload = Marshal.dump(data)
restored = Marshal.load(payload)
```

### Unsupported objects

Some things can't be marshaled (e.g., procs, bindings, IO objects, singleton objects). Catch `TypeError` if you're unsure.

### Practice checklist

- [ ] Serialize a custom class instance to disk and load it back in another script.
- [ ] Attempt to marshal a proc and rescue the resulting `TypeError`.
- [ ] Combine `Marshal.dump` with `StringIO` for in-memory caching.
- [ ] Wrap dump/load in `begin/rescue` blocks and log failures.

Next: continue to Flow Control & Collections, now with simple persistence techniques under your belt.

#### Practice 1 - Sketching Marshal dump/load

**Goal:** Describe how you would serialize a custom class instance to disk and load it back.

#> ruby :practice

# TODO: Print a short example showing Marshal.dump and Marshal.load
# used with a custom class instance and a file.

```solution
puts "File.open('user.dump', 'wb') { |f| Marshal.dump(user, f) }"
puts "user = File.open('user.dump', 'rb') { |f| Marshal.load(f) }"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('Marshal.dump') } && lines.any? { |l| l.include?('Marshal.load') }
```

#!


#### Practice 2 - Rescuing Marshal TypeError

**Goal:** Attempt to marshal a proc and rescue the `TypeError`.

#> ruby :practice

# TODO: Print a snippet that shows attempting to Marshal.dump a proc
# and rescuing TypeError with a friendly message.

```solution
puts "begin"
puts "  Marshal.dump(-> { puts 'hi' })"
puts "rescue TypeError"
puts "  puts 'Cannot marshal procs'"
puts "end"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('TypeError') }
```

#!


#### Practice 3 - Using StringIO for in-memory caching

**Goal:** Combine `Marshal.dump` with `StringIO` for in-memory caching.

#> ruby :practice

# TODO: Print an example using StringIO.new as an in-memory buffer for
# Marshal.dump and Marshal.load.

```solution
puts "buffer = StringIO.new"
puts "Marshal.dump(obj, buffer)"
puts "buffer.rewind"
puts "copy = Marshal.load(buffer)"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('StringIO') }
```

#!


#### Practice 4 - Logging serialization failures

**Goal:** Wrap dump/load in `begin`/`rescue` and log failures.

#> ruby :practice

# TODO: Print a short example that shows using Logger inside
# begin/rescue around serialization calls.

```solution
puts "begin"
puts "  Marshal.dump(config, File.open('config.dump', 'wb'))"
puts "rescue => e"
puts "  logger.error(\"Failed to serialize config: \#{e.message}\")"
puts "end"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('logger') } && lines.any? { |l| l.include?('rescue') }
```

#!

