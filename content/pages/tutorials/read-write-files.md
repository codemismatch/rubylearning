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

<pre class="language-ruby"><code class="language-ruby">
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
</code></pre>

- Modes: `"r"` (read), `"r+"` (read/write), `"w"` (write, truncates/creates), `"a"` (append). You can also specify encodings (`"r:UTF-16LE:UTF-8"`).
- Passing a block ensures the file closes automatically when the block exits. Otherwise call `file.close`.
- `File.readlines` loads the entire file into an array of lines.

### Traversing directories

Use the `Find` module to walk a tree:

<pre class="language-ruby"><code class="language-ruby">
require &quot;find&quot;

Find.find(&quot;./&quot;) do |path|
  type = if File.file?(path)
  &quot;F&quot;
elsif File.directory?(path)
  &quot;D&quot;
else
  &quot;?&quot;
end
puts &quot;#{type}: #{path}&quot;
end
</code></pre>

This example prints each file/directory under the current working directory. You'll learn more about `require` soon--it loads stdlib modules like `Find`.

### Random file access

`IO#seek` repositions the file pointer. Use the `IO::SEEK_*` constants to describe relative moves.

<pre class="language-ruby"><code class="language-ruby">
# p028xrandom.rb
f = File.new("hellousa.rb")  # read-only by default
f.seek(12, IO::SEEK_SET)     # absolute seek to byte 12
puts f.readline              # prints from byte 12 onward
f.close
</code></pre>

`IO::SEEK_CUR` seeks relative to the current position, `IO::SEEK_END` seeks relative to the end (use negative offsets), and `IO::SEEK_SET` is absolute.

### Marshaling preview

Ruby supports object serialization via `Marshal.dump`/`Marshal.load`. We'll revisit this later, but it's mentioned here because file IO often accompanies serialization tasks.

### Practice checklist

- [ ] Open a text file in `"a"` (append) mode and log a timestamped entry.
- [ ] Use `File.readlines` to count the number of lines matching a pattern.
- [ ] Traverse a directory with `Find.find`, filtering only `.rb` files.
- [ ] Seek to the middle of a file and read the remainder to understand pointer positioning.

Next: continue to Flow Control & Collections to keep combining IO with loops, ranges, and data structures.
