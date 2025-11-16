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

> Adapted from Satish Talim's "Ruby Logging" notes.

Logging surfaces what your program is doing without halting execution. Ruby ships a flexible stdlib logger and you can always fall back to simple `puts` or file writes.

### Quick-and-dirty logging

<pre class="language-ruby"><code class="language-ruby">
puts &quot;[DEBUG] Starting import...&quot;
File.open(&quot;app.log&quot;, &quot;a&quot;) { |f| f.puts &quot;#{Time.now} Task finished&quot; }
</code></pre>

Useful for tiny scripts, but you'll quickly want log levels, formatting, and rotation--enter `Logger`.

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

#### Practice 1 - Logger rotation

<p><strong>Goal:</strong> Show how you would construct a rotating logger.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-logging"
     data-practice-index="0"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('Logger.new(\"log/dev.log\", 3, 1024 * 1024)') }"><code class="language-ruby">
# TODO: Print the Logger.new call that configures rotation for
# log/dev.log with a few rotated files and a max size.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-logging"
     data-practice-index="0"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-logging:0">
puts 'Logger.new("log/dev.log", 3, 1024 * 1024)'
</script>

#### Practice 2 - Logging block start/end

<p><strong>Goal:</strong> Create a helper that logs start/end times of a block.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-logging"
     data-practice-index="1"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('start') } && lines.any? { |l| l.downcase.include?('finish') }"><code class="language-ruby">
# TODO: Print an example helper that logs before and after running a
# block using logger.info.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-logging"
     data-practice-index="1"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-logging:1">
puts "def with_logging(logger, message)"
puts "  logger.info(\"start: \#{message}\")"
puts "  yield"
puts "  logger.info(\"finish: \#{message}\")"
puts "end"
</script>

#### Practice 3 - Custom logger.formatter

<p><strong>Goal:</strong> Experiment with a custom `logger.formatter` that prepends timestamps and thread IDs.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-logging"
     data-practice-index="2"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('formatter') } && lines.any? { |l| l.downcase.include?('thread') }"><code class="language-ruby">
# TODO: Print a formatter assignment that includes time and thread id
# in each log line.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-logging"
     data-practice-index="2"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-logging:2">
puts "logger.formatter = proc do |severity, time, progname, msg|"
puts "  \"[\#{time.iso8601}] [\#{Thread.current.object_id}] \#{severity}: \#{msg}\\n\""
puts "end"
</script>

#### Practice 4 - Logging exceptions before re-raising

<p><strong>Goal:</strong> Pair a `begin`/`rescue` block with logging to capture exception messages before re-raising.</p>

<pre class="language-ruby"
     data-executable="true"
     data-practice-chapter="rl:chapter:/tutorials/ruby-logging"
     data-practice-index="3"
     data-test="out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('logger.error') } && lines.any? { |l| l.downcase.include?('raise') }"><code class="language-ruby">
# TODO: Print a snippet where an exception is logged and then
# re-raised to bubble up.
</code></pre>

<div class="practice-feedback"
     data-practice-chapter="rl:chapter:/tutorials/ruby-logging"
     data-practice-index="3"></div>

<script type="text/plain"
        data-practice-solution="rl:chapter:/tutorials/ruby-logging:3">
puts "begin"
puts "  risky_operation"
puts "rescue => e"
puts "  logger.error(\"Failure: \#{e.message}\")"
puts "  raise"
puts "end"
</script>
