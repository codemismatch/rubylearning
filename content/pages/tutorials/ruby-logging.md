---
layout: tutorial
title: "Chapter 34 &ndash; Ruby Logging"
permalink: /tutorials/ruby-logging/
difficulty: beginner
summary: Capture useful diagnostics with the stdlib `Logger`, simple puts-style logs, and rotating files.
previous_tutorial:
  title: "Chapter 33: Ruby Exceptions"
  url: /tutorials/ruby-exceptions/
next_tutorial:
  title: "Chapter 35: Ruby `Time` Class"
  url: /tutorials/ruby-time-class/
related_tutorials:
  - title: "Read/Write Text Files"
    url: /tutorials/read-write-files/
  - title: "Ruby Access Control"
    url: /tutorials/ruby-access-control/
---

> Adapted from Satish Talim’s “Ruby Logging” notes.

Logging surfaces what your program is doing without halting execution. Ruby ships a flexible stdlib logger and you can always fall back to simple `puts` or file writes.

### Quick-and-dirty logging

<pre class="language-ruby"><code class="language-ruby">
puts &quot;[DEBUG] Starting import...&quot;
File.open(&quot;app.log&quot;, &quot;a&quot;) { |f| f.puts &quot;#{Time.now} Task finished&quot; }
</code></pre>

Useful for tiny scripts, but you’ll quickly want log levels, formatting, and rotation—enter `Logger`.

### Using stdlib `Logger`

<pre class="language-ruby"><code class="language-ruby">
require &quot;logger&quot;

logger = Logger.new($stdout)            # or &quot;log/app.log&quot;
logger.level = Logger::INFO             # DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN

logger.info(&quot;Booting service&quot;)
logger.warn(&quot;Slow response: #{duration}s&quot;)
logger.error(&quot;Unhandled exception&quot;, exception: e)
</code></pre>

- Pass a file path, IO, or even `Logger.new("log/app.log", 10, 1024 * 1024)` for rotation (10 files, 1MB each).
- Format messages by setting `logger.formatter`.

### Structured context

Wrap log calls in helper methods or use keyword arguments:

<pre class="language-ruby"><code class="language-ruby">
def log_request(logger, action:, status:)
  logger.info(&quot;[#{action}] status=#{status}&quot;)
end
</code></pre>

### Best practices

- Pick consistent levels so operators know what to grep.
- Avoid logging secrets; redact tokens/passwords.
- Combine with exception handling: rescue errors, log them, then re-raise if needed.

### Practice checklist

- [ ] Use `Logger.new("log/dev.log", 3, 1024 * 1024)` to test file rotation.
- [ ] Create a helper that logs start/end times of a block (`logger.info` before and after).
- [ ] Experiment with custom `logger.formatter` to prepend timestamps and thread IDs.
- [ ] Pair a `begin/rescue` block with logging to capture exception messages before re-raising.

Next: keep building in Flow Control & Collections, now with observability baked in.
