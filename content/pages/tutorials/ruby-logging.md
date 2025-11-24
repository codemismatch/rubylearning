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

```ruby-exec
puts "[DEBUG] Starting import..."
File.open("app.log", "a") { |f| f.puts "#{Time.now} Task finished" }
```

Useful for tiny scripts, but you'll quickly want log levels, formatting, and rotation--enter `Logger`.

### Using stdlib `Logger`

```ruby-exec
begin
  require "monitor"
rescue LoadError
end

unless defined?(MonitorMixin)
  module MonitorMixin
    def mon_initialize; end
    def mon_enter; end
    def mon_exit; end
  end
end

require "logger"

logger = Logger.new($stdout)            # or "log/app.log"
logger.level = Logger::INFO             # DEBUG, INFO, WARN, ERROR, FATAL, UNKNOWN

logger.info("Booting service")
logger.warn("Slow response: #{duration}s")
logger.error("Unhandled exception", exception: e)
```

- Pass a file path, IO, or even `Logger.new("log/app.log", 10, 1024 * 1024)` for rotation (10 files, 1MB each).
- Format messages by setting `logger.formatter`.

### Structured context

Wrap log calls in helper methods or use keyword arguments:

```ruby-exec
def log_request(logger, action:, status:)
  logger.info("[#{action}] status=#{status}")
end
```

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

**Goal:** Show how you would construct a rotating logger.

#> ruby :practice

# TODO: Print the Logger.new call that configures rotation for
# log/dev.log with a few rotated files and a max size.

```solution
begin
  require "monitor"
rescue LoadError
end

unless defined?(MonitorMixin)
  module MonitorMixin
    def mon_initialize; end
    def mon_enter; end
    def mon_exit; end
  end
end

require "logger"
require "fileutils"

FileUtils.mkdir_p("log")
logger = Logger.new("log/dev.log", 3, 1024 * 1024)
logger.info("Logger rotation configured")
puts "Logger destination: #{logger.instance_variable_get(:@logdev).filename}"
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('Logger destination') }
```

#!


#### Practice 2 - Logging block start/end

**Goal:** Create a helper that logs start/end times of a block.

#> ruby :practice

# TODO: Print an example helper that logs before and after running a
# block using logger.info.

```solution
begin
  require "monitor"
rescue LoadError
end

unless defined?(MonitorMixin)
  module MonitorMixin
    def mon_initialize; end
    def mon_enter; end
    def mon_exit; end
  end
end

require "logger"

def with_logging(logger, message)
  logger.info("start: #{message}")
  yield
ensure
  logger.info("finish: #{message}")
end

logger = Logger.new($stdout)
with_logging(logger, "demo task") { puts "running task" }
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.downcase.include?('start: demo task') } && lines.any? { |l| l.downcase.include?('finish: demo task') }
```

#!


#### Practice 3 - Custom logger.formatter

**Goal:** Experiment with a custom `logger.formatter` that prepends timestamps and thread IDs.

#> ruby :practice

# TODO: Print a formatter assignment that includes time and thread id
# in each log line.

```solution
begin
  require "monitor"
rescue LoadError
end

unless defined?(MonitorMixin)
  module MonitorMixin
    def mon_initialize; end
    def mon_enter; end
    def mon_exit; end
  end
end

require "logger"
require "time"

logger = Logger.new($stdout)
logger.formatter = proc do |severity, time, _progname, msg|
  "[#{time.iso8601}] [#{Thread.current.object_id}] #{severity}: #{msg}\n"
end

logger.info("formatted log entry")
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('formatted log entry') } && lines.any? { |l| l.include?('INFO:') }
```

#!


#### Practice 4 - Logging exceptions before re-raising

**Goal:** Pair a `begin`/`rescue` block with logging to capture exception messages before re-raising.

#> ruby :practice

# TODO: Print a snippet where an exception is logged and then
# re-raised to bubble up.

```solution
begin
  require "monitor"
rescue LoadError
end

unless defined?(MonitorMixin)
  module MonitorMixin
    def mon_initialize; end
    def mon_enter; end
    def mon_exit; end
  end
end

require "logger"

def risky_operation
  raise "boom"
end

logger = Logger.new($stdout)

begin
  begin
    risky_operation
  rescue => e
    logger.error("Failure: #{e.message}")
    raise
  end
rescue => e
  puts "Outer rescue caught: #{e.message}"
end
```

```test
out = output.string; lines = out.lines.map(&:strip); lines.any? { |l| l.include?('Failure: boom') } && lines.any? { |l| l.include?('Outer rescue caught') }
```

#!
