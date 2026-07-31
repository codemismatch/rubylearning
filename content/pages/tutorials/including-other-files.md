---
layout: tutorial
title: "Chapter 27 &ndash; Including Other Files"
permalink: /courses/ruby-basics/including-other-files/
difficulty: beginner
summary: Share code across Ruby files with `require`, `load`, and `require_relative`, and understand how Ruby locates those files.
previous_tutorial:
  title: "Chapter 26: Ruby Procs & Lambdas"
  url: /courses/ruby-basics/ruby-procs/
next_tutorial:
  title: "Chapter 28: Ruby Open Classes"
  url: /courses/ruby-basics/ruby-open-classes/
related_tutorials:
  - title: "Ruby Hashes"
    url: /courses/ruby-basics/ruby-hashes/
  - title: "Read/Write Text Files"
    url: /courses/ruby-basics/read-write-files/
date: 2025-11-14
---

> Adapted from Satish Talim's "Including Other Files" lesson.

As your Ruby programs grow, you'll split code across files. Ruby provides three helpers:

- `require` - loads a file once, searching `$LOAD_PATH` (aliased as `$:`).
- `load` - forcibly reloads a file every time you call it.
- `require_relative` - loads a file relative to the current file's directory.

### `require`

Use `require` for gems, stdlib components, or project files that should load at most once per process.

```ruby-exec
# Demonstrate require behavior
# Note: 'js' library is pre-loaded in WASM, so it returns false
result1 = require "js"
puts "require 'js': #{result1} (already loaded in WASM)"

# Demonstrate LoadError when library doesn't exist
begin
  require "nonexistent_library"
  puts "Library loaded"
rescue LoadError => e
  puts "LoadError: #{e.message}"
end

puts "\nKey points:"
puts "- require returns true on first load, false if already loaded"
puts "- require raises LoadError if file can't be found"
puts "- In production: require 'json', require 'pg', require_relative 'file'"
```

`require` returns `true` when it loads a file, `false` when the file was already loaded, and raises `LoadError` if it can't find the file.

Ruby looks through each directory in `$LOAD_PATH` for the requested file. You can inspect or modify the path:

```ruby-exec
# Inspect the load path
puts "Current $LOAD_PATH:"
$LOAD_PATH.each { |path| puts "  #{path}" }

# You can modify it (though file loading is limited in WASM)
puts "\nAdding custom path:"
$LOAD_PATH.unshift "/custom/lib"
puts "First path is now: #{$LOAD_PATH.first}"
```

### `load`

`load "scripts/setup.rb"` reprocesses the file every time you call it. You can pass a second argument of `true` to wrap the loaded code in an anonymous module.

**Note:** In the WASM environment, we can't load external files, but `eval` demonstrates the same concept of re-executing code:

```ruby-exec
# In WASM, we can't load external files, but we can demonstrate
# the concept using eval (which re-executes code each time)

script_code = <<~RUBY
  puts "Script executed at: " + Time.now.to_s
  $counter ||= 0
  $counter += 1
  puts "Execution count: " + $counter.to_s
RUBY

puts "First execution:"
eval(script_code)

puts "\nSecond execution (code runs again):"
eval(script_code)
```

This is handy for DSLs or when you need the latest version of a file during development.

### `require_relative`

For project-local files, `require_relative` resolves paths relative to the file containing the call.

**Note:** In the WASM environment, there's no file system context, so we demonstrate the concept using inline code:

```ruby-exec
# require_relative doesn't work in WASM (no file system context)
# Instead, define code inline or use eval

# Simulate what require_relative would do:
user_code = <<~RUBY
  class User
    attr_accessor :name, :email
    
    def initialize(name, email)
      @name = name
      @email = email
    end
    
    def to_s
      "User: " + @name.to_s + " <" + @email.to_s + ">"
    end
  end
RUBY

eval(user_code)

# Now use the User class
user = User.new("Satish Talim", "satish@example.com")
puts user.to_s
```

This avoids fiddling with `$LOAD_PATH` and keeps dependencies explicit.

### Splitting code across files

In a normal Ruby environment, you can split code across multiple files. Here's how it would work conceptually:

**Note:** The WASM environment runs code in isolation, so we demonstrate the pattern inline:

```ruby-exec
# In WASM, we can't split code across files, so we define everything inline

# Helper method (would normally be in abbrev.rb)
def short_name(full_name)
  full_name.split.first
end

# Main code (would normally be in testabbrev.rb)
puts "Short name: #{short_name('Satish Talim')}"
puts "Short name: #{short_name('Matz Matsumoto')}"

# This demonstrates the concept even though it's in one block
```

### Practice checklist

- [ ] Understand how `require` loads libraries in production Ruby.
- [ ] Inspect `$LOAD_PATH` to see where Ruby looks for files.
- [ ] Use `eval` to execute code multiple times and observe re-execution.
- [ ] Rescue `LoadError` to provide a helpful message when a library is missing.

**Note:** In production Ruby, you would use `require "library"` to load gems and stdlib, `require_relative` for project files, and `load` for scripts. The WASM environment demonstrates these concepts differently due to its sandboxed nature.

Next: return to Flow Control & Collections to keep building on these reusable building blocks.

#### Practice 1 - Understanding require

**Goal:** Understand how `require` works in production Ruby.

#> ruby :practice

# TODO: Print examples of how require would be used in production Ruby.

```solution
puts "Loading libraries with require:"
puts
puts "require 'json'        # Loads JSON from stdlib"
puts "require 'rails'       # Loads Rails gem"
puts "require_relative 'helpers/string_utils'  # Loads local file"
puts
puts "require returns true on first load, false if already loaded"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('require') }
```

#!


#### Practice 2 - Inspecting $LOAD_PATH

**Goal:** Inspect and understand the `$LOAD_PATH` variable.

#> ruby :practice

# TODO: Print the first 3 paths in $LOAD_PATH and show how to add a path.

```solution
puts "First 3 load paths:"
$LOAD_PATH.first(3).each { |path| puts "  #{path}" }

puts "\nAdding custom path:"
$LOAD_PATH.unshift("/my/custom/lib")
puts "New first path: #{$LOAD_PATH.first}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('load path') || l.include?('LOAD_PATH') }
```

#!


#### Practice 3 - Using eval to re-execute code

**Goal:** Use `eval` to execute code multiple times and observe re-execution.

#> ruby :practice

# TODO: Use eval to execute a code string twice and show that it runs both times.

```solution
code = 'puts "Executed at: " + Time.now.to_s'

puts "First run:"
eval(code)

puts "\nSecond run:"
eval(code)
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.count { |l| l.include?('Executed at:') } >= 2
```

#!


#### Practice 4 - Rescuing LoadError

**Goal:** Show how you would rescue `LoadError` for a missing library.

#> ruby :practice

# TODO: Use begin/rescue to handle a LoadError when requiring a non-existent library.

```solution
begin
  require 'nonexistent_gem'
  puts "Library loaded successfully"
rescue LoadError => e
  puts "Could not load library: #{e.message}"
  puts "Install the gem or check your $LOAD_PATH"
end
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('Could not load') }
```

#!
