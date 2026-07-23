---
layout: tutorial
title: "Chapter 39 &ndash; Object Serialization (Marshal)"
permalink: /courses/ruby-basics/object-serialization/
difficulty: beginner
summary: Persist Ruby objects by dumping and loading them with the built-in `Marshal` module.
previous_tutorial:
  title: "Chapter 38: Mutable vs Immutable Objects"
  url: /courses/ruby-basics/mutable-and-immutable-objects/
next_tutorial:
  title: "Chapter 40: Modules & Mixins"
  url: /courses/ruby-basics/modules-and-mixins/
related_tutorials:
  - title: "Read/Write Text Files"
    url: /courses/ruby-basics/read-write-files/
  - title: "Ruby Exceptions"
    url: /courses/ruby-basics/ruby-exceptions/
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
data = { name: "Satish", skills: %w[ruby rails] }
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

# TODO: Serialize a custom class instance to disk and load it back.

```solution
class User
  attr_accessor :name, :email
  
  def initialize(name, email)
    @name = name
    @email = email
  end
end

path = "user.dump"

user = User.new("Alice", "alice@example.com")

File.open(path, "wb") { |f| Marshal.dump(user, f) }
loaded = File.open(path, "rb") { |f| Marshal.load(f) }

puts "Original: #{user.name}, #{user.email}"
puts "Loaded: #{loaded.name}, #{loaded.email}"
puts "Equal: #{user.name == loaded.name && user.email == loaded.email}"

File.delete(path) if File.exist?(path)
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('Original:') } && lines.any? { |l| l.include?('Loaded:') } && lines.any? { |l| l.include?('Equal: true') }
```

#!


#### Practice 2 - Rescuing Marshal TypeError

**Goal:** Attempt to marshal a proc and rescue the `TypeError`.

#> ruby :practice

# TODO: Attempt to marshal a proc and rescue the TypeError.

```solution
begin
  Marshal.dump(-> { puts 'hi' })
  puts "Successfully marshaled"
rescue TypeError => e
  puts "Cannot marshal procs: #{e.message}"
end
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('cannot marshal') }
```

#!


#### Practice 3 - Using StringIO for in-memory caching

**Goal:** Combine `Marshal.dump` with `StringIO` for in-memory caching.

#> ruby :practice

# TODO: Use StringIO as an in-memory buffer for Marshal operations.

```solution
require "stringio"

data = { name: "Ruby", version: 3.2 }

buffer = StringIO.new
Marshal.dump(data, buffer)
buffer.rewind
copy = Marshal.load(buffer)

puts "Original: #{data.inspect}"
puts "Copied: #{copy.inspect}"
puts "Equal: #{data == copy}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('Original:') } && lines.any? { |l| l.include?('Equal: true') }
```

#!


#### Practice 4 - Logging serialization failures

**Goal:** Wrap dump/load in `begin`/`rescue` and log failures.

#> ruby :practice

# TODO: Wrap dump/load in begin/rescue and handle failures.

```solution
config = { host: "localhost", port: 3000 }
path = "config.dump"

begin
  File.open(path, "wb") { |f| Marshal.dump(config, f) }
  loaded = File.open(path, "rb") { |f| Marshal.load(f) }
  puts "Serialization successful: #{loaded.inspect}"
rescue => e
  puts "Failed to serialize: #{e.class} - #{e.message}"
ensure
  File.delete(path) if File.exist?(path)
end
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('serialization successful') }
```

#!
