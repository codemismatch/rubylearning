---
layout: page
title: Test Ruby Exec
permalink: /test-ruby-exec/
---

### Test File Operations and Shell Emulation

```ruby-exec
File.write("test.txt", "Hello from VFS!")
puts "File written."

puts "--- ls output ---"
puts `ls`

puts "--- cat output ---"
puts `cat test.txt`

puts "--- pwd output ---"
puts `pwd`

File.delete("test.txt")
puts "File deleted."
puts "--- ls output after delete ---"
puts `ls`
```
