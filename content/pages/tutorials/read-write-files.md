---
layout: tutorial
title: "Chapter 22 &ndash; Read/Write Text Files"
permalink: /tutorials/read-write-files/
difficulty: beginner
summary: Use Ruby's IO classes to read, write, traverse directories, and seek within files while keeping resources safely closed.
previous_tutorial:
  title: "Chapter 21: Ruby Random Numbers"
  url: /tutorials/ruby-random-numbers/
next_tutorial:
  title: "Chapter 23: Ruby Regular Expressions"
  url: /tutorials/ruby-regular-expressions/
related_tutorials:
  - title: "Ruby Arrays"
    url: /tutorials/ruby-arrays/
  - title: "Ruby Hashes"
    url: /tutorials/ruby-hashes/
---

> Adapted from Satish Talim's Read/Write Files lesson.

Ruby's `IO` family (which `File` inherits from) handles disk operations. You can open files in read, write, append, or combined modes, and Ruby auto-closes them when you pass a block to `File.open`.

### Reading and writing files

```ruby-exec
# p027readwrite.rb
# Read a file
File.open("p014constructs.rb", "r") do |file|
  while line = file.gets
    puts line
  end
end

# Write a file
File.open("test.rb", "w") do |file|
  file.puts "Created by Satish"
  file.puts "Thank God!"
end
```

- Modes: `"r"` (read), `"r+"` (read/write), `"w"` (write, truncates/creates), `"a"` (append). You can also specify encodings (`"r:UTF-16LE:UTF-8"`).
- Passing a block ensures the file closes automatically when the block exits. Otherwise call `file.close`.
- `File.readlines` loads the entire file into an array of lines.

### Traversing directories

Use the `Find` module to walk a tree:

```ruby-exec
require "find"

Find.find("./") do |path|
  type = if File.file?(path)
  "F"
elsif File.directory?(path)
  "D"
else
  "?"
end
puts "#{type}: #{path}"
end
```

This example prints each file/directory under the current working directory. You'll learn more about `require` soon--it loads stdlib modules like `Find`.

### Random file access

`IO#seek` repositions the file pointer. Use the `IO::SEEK_*` constants to describe relative moves.

```ruby-exec
# p028xrandom.rb
f = File.new("hellousa.rb")  # read-only by default
f.seek(12, IO::SEEK_SET)     # absolute seek to byte 12
puts f.readline              # prints from byte 12 onward
f.close
```

`IO::SEEK_CUR` seeks relative to the current position, `IO::SEEK_END` seeks relative to the end (use negative offsets), and `IO::SEEK_SET` is absolute.

### Marshaling preview

Ruby supports object serialization via `Marshal.dump`/`Marshal.load`. We'll revisit this later, but it's mentioned here because file IO often accompanies serialization tasks.

### Practice checklist

- [ ] Open a text file in `"a"` (append) mode and log a timestamped entry.
- [ ] Use `File.readlines` to count the number of lines matching a pattern.
- [ ] Traverse a directory with `Find.find`, filtering only `.rb` files.
- [ ] Seek to the middle of a file and read the remainder to understand pointer positioning.

Next: continue to Flow Control & Collections to keep combining IO with loops, ranges, and data structures.

#### Practice 1 - Appending a timestamped entry

**Goal:** Sketch how you would append a timestamped entry to a log file.

#> ruby :practice

# TODO: Print a snippet that opens a file in \"a\" mode and writes a
# timestamped line.

```solution
puts 'File.open("log.txt", "a") { |f| f.puts("[\#{Time.now}] Started app") }'
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('File.open') } && lines.any? { |l| l.include?('\
```

#!


#### Practice 2 - Counting matching lines

**Goal:** Describe how you would use `File.readlines` to count matching lines.

#> ruby :practice

# TODO: Print an example that reads all lines from a file and counts
# those matching a pattern.

```solution
puts 'count = File.readlines("log.txt").count { |line| line.include?("ERROR") }'
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('File.readlines') }
```

#!


#### Practice 3 - Traversing directories with Find.find

**Goal:** Use `Find.find` to traverse a directory tree and select `.rb` files.

#> ruby :practice

# TODO: Print a snippet that walks a directory tree and prints only
# Ruby files.

```solution
puts 'Find.find(".") { |path| puts path if path.end_with?(".rb") }'
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('Find.find') } && lines.any? { |l| l.include?('.rb') }
```

#!


#### Practice 4 - Seeking within a file

**Goal:** Show how you would seek to the middle of a file and read the remainder.

#> ruby :practice

# TODO: Print an example that uses IO#seek to move to a position and
# then reads the rest of the file.

```solution
puts 'File.open("data.txt", "r") do |f|'
puts '  f.seek(f.size / 2)'
puts '  tail = f.read'
puts 'end'
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('.seek(') }
```

#!

