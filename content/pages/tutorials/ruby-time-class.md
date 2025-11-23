---
layout: tutorial
title: "Chapter 35 &ndash; Ruby `Time` Class"
permalink: /tutorials/ruby-time-class/
difficulty: beginner
summary: Create, format, and manipulate timestamps with Ruby's `Time` helpers.
previous_tutorial:
  title: "Chapter 34: Ruby Logging"
  url: /tutorials/ruby-logging/
next_tutorial:
  title: "Chapter 36: Duck Typing"
  url: /tutorials/duck-typing/
related_tutorials:
  - title: "Read/Write Text Files"
    url: /tutorials/read-write-files/
  - title: "Ruby Exceptions"
    url: /tutorials/ruby-exceptions/
---

> Adapted from Satish Talim's "Ruby Time Class" lesson.

The `Time` class handles timestamps, duration math, and formatting.

### Creating times

```ruby-exec
now = Time.now
birthday = Time.new(2025, 1, 15, 12, 0, 0)   # local time
utc_time = Time.utc(2025, 1, 15, 12)         # UTC
```

### Accessors

```ruby-exec
now = Time.now
puts now.year   #=> 2025
puts now.month  #=> 1
puts now.day    #=> 15
puts now.hour   #=> 9 (depends on TZ)
puts now.wday   # 0 = Sunday
puts now.yday   # day of year
```

### Formatting

Use `strftime` for custom strings:

```ruby-exec
now = Time.now
now.strftime("%Y-%m-%d %H:%M:%S")  #=> "2025-01-15 09:30:00"
now.to_s                           # default formatting
now.ctime                          # ctime-style string
```

### Arithmetic & comparison

```ruby-exec
now = Time.now
deadline = now + 60      # add seconds
elapsed = Time.now - now # difference in seconds

puts "deadline passed" if Time.now > deadline
```

`Time` objects include `Comparable`, so you get `<`, `<=`, `>=`, etc.

### Time zones

- `time.utc?`, `time.getutc`, `time.localtime` to convert.
- Set `ENV["TZ"]` for scripts that need a specific zone.

### Practice checklist

- [ ] Format the current time as `YYYY/MM/DD HH:MM`.
- [ ] Compute how many seconds remain until midnight.
- [ ] Convert `Time.now` to UTC, then back to local.
- [ ] Measure how long a block takes by capturing `start = Time.now` and subtracting.

Next: keep building in Flow Control & Collections, now with timestamps for logging or scheduling.

#### Practice 1 - Formatting the current time

**Goal:** Format the current time as `YYYY/MM/DD HH:MM`.

#> ruby :practice

# TODO: Use Time.now.strftime to print the current time as
# YYYY/MM/DD HH:MM.

```solution
puts Time.now.strftime("%Y/%m/%d %H:%M")
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.match(/\\d{4}\\/\\d{2}\\/\\d{2} \\d{2}:\\d{2}/) }
```

#!


#### Practice 2 - Seconds until midnight

**Goal:** Compute how many seconds remain until midnight.

#> ruby :practice

# TODO: Calculate the time difference between now and the next
# midnight, and print it in seconds.

```solution
now = Time.now
midnight = Time.new(now.year, now.month, now.day) + 24 * 60 * 60
seconds = (midnight - now).to_i
puts "seconds until midnight: #{seconds}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('seconds until midnight') }
```

#!


#### Practice 3 - Converting to UTC and back

**Goal:** Convert `Time.now` to UTC, then back to local.

#> ruby :practice

# TODO: Print both the UTC and local representations of the current
# time.

```solution
now = Time.now
puts "utc:   #{now.utc}"
puts "local: #{now.localtime}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('utc') } && lines.any? { |l| l.downcase.include?('local') }
```

#!


#### Practice 4 - Measuring block duration

**Goal:** Measure how long a block takes using `Time.now` before and after.

#> ruby :practice

# TODO: Capture start = Time.now, run some work, then print the
# elapsed seconds.

```solution
start = Time.now
sleep 0.1
elapsed = Time.now - start
puts "elapsed: #{elapsed} seconds"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('elapsed') }
```

#!

