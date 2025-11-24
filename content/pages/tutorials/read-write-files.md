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
# First, create a sample file to read
File.open("sample.txt", "w") do |file|
  file.puts "Line 1: Hello Ruby"
  file.puts "Line 2: File I/O is easy"
  file.puts "Line 3: Reading files"
end

# Read the file
puts "Reading sample.txt:"
File.open("sample.txt", "r") do |file|
  while line = file.gets
    puts line
  end
end

# Write a new file
File.open("output.txt", "w") do |file|
  file.puts "Created by Satish"
  file.puts "Thank God!"
end

puts "\nWrote to output.txt successfully!"
```

- Modes: `"r"` (read), `"r+"` (read/write), `"w"` (write, truncates/creates), `"a"` (append). You can also specify encodings (`"r:UTF-16LE:UTF-8"`).
- Passing a block ensures the file closes automatically when the block exits. Otherwise call `file.close`.
- `File.readlines` loads the entire file into an array of lines.

### Traversing directories

Use `Dir.entries` and `Dir` methods to walk directory structures:

```ruby-exec
# Create a simple directory structure
Dir.mkdir("test_dir") unless Dir.exist?("test_dir")
File.write("test_dir/file1.rb", "# Ruby file")
File.write("test_dir/file2.txt", "Text file")

# Traverse directories using Dir methods (Find module not available in WASM)
puts "Current directory contents:"
Dir.entries(".").each do |entry|
  next if entry.start_with?(".")
  path = File.join(".", entry)
  type = if File.file?(path)
    "F"
  elsif File.directory?(path)
    "D"
  else
    "?"
  end
  puts "#{type}: #{path}"
end

puts "\ntest_dir contents:"
Dir.entries("test_dir").each do |entry|
  next if entry.start_with?(".")
  path = File.join("test_dir", entry)
  type = File.file?(path) ? "F" : "D"
  puts "#{type}: #{path}"
end
```

This example creates a test directory structure and prints each file/directory. `Dir.entries` returns an array of filenames in the given directory. You'll learn more about `require` soon--it loads stdlib modules.

### Random file access

`IO#seek` repositions the file pointer. Use the `IO::SEEK_*` constants to describe relative moves.

```ruby-exec
# p028xrandom.rb
# First create a sample file
File.write("hellousa.rb", "puts 'Hello USA!'\nputs 'Welcome to Ruby'\nputs 'File I/O demo'")

# Now demonstrate random access
f = File.new("hellousa.rb")  # read-only by default
puts "Full file content:"
puts f.read
f.rewind

puts "\nSeeking to byte 12:"
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
- [ ] Traverse a directory with `Dir.entries`, filtering only `.rb` files.
- [ ] Seek to the middle of a file and read the remainder to understand pointer positioning.

Next: continue to Flow Control & Collections to keep combining IO with loops, ranges, and data structures.

#### Practice 1 - Appending a timestamped entry

**Goal:** Sketch how you would append a timestamped entry to a log file.

#> ruby :practice

# TODO: Print a snippet that opens a file in \"a\" mode and writes a
# timestamped line.

```solution
# Create a log file and append to it
log_path = "app.log"

# Append a timestamped entry
File.open(log_path, "a") { |f| f.puts("[#{Time.now}] Started app") }

# Read and display the log
puts "Log contents:"
puts File.read(log_path)
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('Started app') }
```

#!


#### Practice 2 - Counting matching lines

**Goal:** Describe how you would use `File.readlines` to count matching lines.

#> ruby :practice

# TODO: Print an example that reads all lines from a file and counts
# those matching a pattern.

```solution
# Create a log file with sample data
log_path = "server.log"
File.write(log_path, "INFO boot\nERROR failure\nINFO finish\nERROR timeout\n")

# Count lines matching a pattern
count = File.readlines(log_path).count { |line| line.include?("ERROR") }
puts "error lines: #{count}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('error lines:') }
```

#!


#### Practice 3 - Traversing directories with Dir.entries

**Goal:** Use `Dir.entries` to traverse a directory and select `.rb` files.

#> ruby :practice

# TODO: Print a snippet that walks a directory tree and prints only
# Ruby files.

```solution
# Create a test directory with files
test_dir = "project"
Dir.mkdir(test_dir) unless Dir.exist?(test_dir)
File.write(File.join(test_dir, "example.rb"), "# sample")
File.write(File.join(test_dir, "notes.txt"), "ignore")
File.write(File.join(test_dir, "main.rb"), "# main file")

# Walk directory and filter .rb files
Dir.entries(test_dir).each do |entry|
  next if entry.start_with?(".")
  path = File.join(test_dir, entry)
  puts "ruby file: #{path}" if path.end_with?(".rb")
end
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('ruby file:') }
```

#!


#### Practice 4 - Seeking within a file

**Goal:** Show how you would seek to the middle of a file and read the remainder.

#> ruby :practice

# TODO: Print an example that uses IO#seek to move to a position and
# then reads the rest of the file.

```solution
# Create a data file
data_path = "alphabet.txt"
File.write(data_path, "ABCDEFGHIJKLMNOPQRSTUVWXYZ")

# Seek to the middle and read the remainder
File.open(data_path, "r") do |f|
  file_size = File.size(data_path)
  f.seek(file_size / 2, IO::SEEK_SET)
  puts "tail: #{f.read}"
end
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('tail:') }
```

#!
