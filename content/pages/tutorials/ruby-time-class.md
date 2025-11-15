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

<pre class="language-ruby"><code class="language-ruby">
now = Time.now
birthday = Time.new(2025, 1, 15, 12, 0, 0)   # local time
utc_time = Time.utc(2025, 1, 15, 12)         # UTC
</code></pre>

### Accessors

<pre class="language-ruby"><code class="language-ruby">
now = Time.now
puts now.year   #=&gt; 2025
puts now.month  #=&gt; 1
puts now.day    #=&gt; 15
puts now.hour   #=&gt; 9 (depends on TZ)
puts now.wday   # 0 = Sunday
puts now.yday   # day of year
</code></pre>

### Formatting

Use `strftime` for custom strings:

<pre class="language-ruby"><code class="language-ruby">
now = Time.now
now.strftime(&quot;%Y-%m-%d %H:%M:%S&quot;)  #=&gt; &quot;2025-01-15 09:30:00&quot;
now.to_s                           # default formatting
now.ctime                          # ctime-style string
</code></pre>

### Arithmetic & comparison

<pre class="language-ruby"><code class="language-ruby">
now = Time.now
deadline = now + 60      # add seconds
elapsed = Time.now - now # difference in seconds

puts &quot;deadline passed&quot; if Time.now &gt; deadline
</code></pre>

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
