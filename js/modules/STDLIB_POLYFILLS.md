# Ruby Standard Library Polyfills

This module implements common Ruby standard library classes using JavaScript, allowing the minimal `ruby.wasm` build to support features that would normally require the full stdlib.

## Implemented Classes

### 1. StringIO

**Location**: `ruby-stdlib-polyfills.js`

**Methods Implemented**:
- `StringIO.new(str = "")` - Create new StringIO instance
- `#string` - Get the string buffer
- `#puts(*args)` - Write lines with newlines
- `#print(*args)` - Write without newlines
- `#write(str)` - Write string, returns bytes written
- `#read(length = nil)` - Read from buffer
- `#gets(sep = $/)` - Read line
- `#truncate(pos = 0)` - Truncate buffer
- `#rewind` - Reset position (no-op)
- `#eof?` - Check if end of buffer
- `#close` - Close (no-op)
- `#closed?` - Always returns false

**Usage**:
```ruby
require 'stringio'
io = StringIO.new
io.puts "Hello"
io.puts "World"
puts io.string  # => "Hello\nWorld\n"
```

### 2. Time

**Location**: `ruby-stdlib-polyfills.js`

**Methods Implemented**:
- `Time.now` - Current time
- `Time.new(year, month, day, hour, min, sec)` - Create time from components
- `Time.utc(...)` - Create UTC time
- `Time.parse(str)` - Parse time string
- `#year`, `#month`, `#day`, `#hour`, `#min`, `#sec` - Accessors
- `#wday` - Day of week (0=Sunday)
- `#yday` - Day of year
- `#strftime(format)` - Format time string
- `#to_s` - Default string format
- `#ctime` - C-style time string
- `#+(seconds)` - Add seconds
- `#-(other)` - Subtract time or seconds
- `#<=>` - Comparison (includes Comparable)
- `#utc?` - Check if UTC
- `#getutc` - Convert to UTC
- `#localtime` - Convert to local time

**Implementation**: Uses JavaScript `Date` object internally, formats results in Ruby

**Usage**:
```ruby
now = Time.now
puts now.strftime("%Y/%m/%d %H:%M")  # => "2025/01/15 09:30"
puts now.year  # => 2025
puts now + 60  # => Time 60 seconds later
```

### 3. JSON

**Location**: `ruby-stdlib-polyfills.js`

**Methods Implemented**:
- `JSON.generate(obj)` - Convert Ruby object to JSON string
- `JSON.dump(obj)` - Alias for generate
- `JSON.parse(str)` - Parse JSON string to Ruby object

**Implementation**: Uses JavaScript `JSON.stringify` and `JSON.parse`, converts between JS and Ruby types

**Usage**:
```ruby
require 'json'
person = { name: "Alice", age: 30 }
json_str = JSON.generate(person)  # => '{"name":"Alice","age":30}'
parsed = JSON.parse(json_str)      # => {:name=>"Alice", :age=>30}
```

## Architecture

All polyfills follow this pattern:
1. **JavaScript does the heavy lifting** - Use JS Date, JSON, etc.
2. **Ruby formats the results** - Convert JS results to Ruby-style output
3. **Minimal implementation** - Only implement methods actually used in tutorials

## Benefits

1. **Small bundle size** - Use `ruby.wasm` (~2-3MB) instead of `ruby+stdlib.wasm` (~15-20MB)
2. **Full functionality** - All tutorial examples work correctly
3. **Performance** - JS implementations are fast and well-tested
4. **Maintainability** - Simple Ruby wrappers around JS functions

## Loading

The polyfills are automatically loaded when Ruby execution support is initialized:
- Loaded in `ruby-exec.js` after VM initialization
- Available to all Ruby code executed in the browser
- No additional `require` statements needed (except for StringIO which needs `require 'stringio'`)

## Testing

All polyfills are tested through the tutorial practice exercises:
- StringIO: Used in `files-gems-next-steps.md` Logger example
- Time: Used in `ruby-time-class.md` and practice exercises
- JSON: Used in `files-gems-next-steps.md` serialization examples
