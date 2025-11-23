# Typophic Crystal Port Migration Guide

This document tracks the migration of Typophic from Ruby to Crystal.

## Why Crystal?

- **Native compilation**: Single binary, no runtime dependencies
- **Ruby-like syntax**: Easier port than complete rewrite
- **Performance**: Faster than Ruby in most cases
- **Simple deployment**: One executable file
- **No complex setup**: No GraalVM, no JVM, just compile and run

## Project Structure

```
crystal/
├── shard.yml              # Crystal dependencies (like Gemfile)
├── src/
│   ├── typophic.cr         # Main entry point
│   ├── typophic/
│   │   ├── cli.cr          # CLI routing
│   │   ├── builder.cr      # Site builder
│   │   ├── version.cr      # Version info
│   │   └── commands/       # Command implementations
│   └── bin/
│       └── typophic        # Executable entry point
└── spec/                   # Tests (optional)
```

## Key Differences: Ruby → Crystal

### 1. Type System
- **Ruby**: Dynamic typing
- **Crystal**: Static typing with type inference

```ruby
# Ruby
def process_file(file)
  content = File.read(file)
  # ...
end
```

```crystal
# Crystal
def process_file(file : String)
  content = File.read(file)
  # ...
end
```

### 2. String Handling
- **Ruby**: Mutable strings by default
- **Crystal**: Immutable strings, use `String::Builder` for concatenation

```ruby
# Ruby
html = ""
html << "<div>"
html << content
```

```crystal
# Crystal
html = String::Builder.new
html << "<div>"
html << content
html.to_s
```

### 3. Nil Handling
- **Ruby**: `nil` can be returned anywhere
- **Crystal**: Must explicitly handle `nil` with `?` or `!`

```ruby
# Ruby
value = hash["key"]  # might be nil
```

```crystal
# Crystal
value = hash["key"]?  # returns String | Nil
value = hash["key"]!  # raises if nil
```

### 4. Modules and Classes
- Similar syntax, but stricter

### 5. File Operations
- Very similar, Crystal has good stdlib support

### 6. Template Rendering
- **Ruby**: ERB (built-in)
- **Crystal**: Use `crinja` or `mustache` shards, or implement simple template engine

## Dependencies Mapping

| Ruby Gem | Crystal Shard | Notes |
|----------|---------------|-------|
| `webrick` | `http/server` | Built-in HTTP server |
| `listen` | `file_monitor` | File watching |
| `rubocop` | `ameba` | Linter (optional) |
| ERB | `crinja` or custom | Template engine |
| YAML | `yaml` | Built-in YAML support |
| JSON | `json` | Built-in JSON support |

## Migration Strategy

### Phase 1: Core Structure ✅
- [x] Set up Crystal project
- [x] Create basic CLI structure
- [ ] Port version and constants

### Phase 2: CLI and Commands
- [ ] Port CLI routing
- [ ] Port command base class
- [ ] Port help/version commands

### Phase 3: Core Builder
- [ ] Port Builder class
- [ ] Port file reading/writing
- [ ] Port YAML/JSON parsing
- [ ] Port front matter parsing

### Phase 4: Template System
- [ ] Choose template engine (crinja or custom)
- [ ] Port ERB template rendering
- [ ] Port partial system
- [ ] Port helper methods

### Phase 5: Content Processing
- [ ] Port markdown processing
- [ ] Port pipeline system
- [ ] Port code block processing
- [ ] Port collection indexing

### Phase 6: Commands
- [ ] Port build command
- [ ] Port serve command (with HTTP server)
- [ ] Port deploy command
- [ ] Port other commands

### Phase 7: Polish
- [ ] Error handling
- [ ] Logging
- [ ] Testing
- [ ] Documentation

## Building and Running

```bash
# Install Crystal (if not already)
brew install crystal

# Install dependencies
cd crystal
shards install

# Build
crystal build src/typophic.cr -o bin/typophic

# Run
./bin/typophic help
```

## Performance Expectations

- **Startup time**: ~10-50ms (vs Ruby's ~100-500ms)
- **Build speed**: 2-5x faster than Ruby
- **Memory usage**: Lower than Ruby
- **Binary size**: ~5-15MB (single file, no dependencies)

## Notes

- Crystal's syntax is very similar to Ruby, making porting straightforward
- Some Ruby idioms need adjustment (nil handling, string building)
- Crystal's type system will catch many bugs during compilation
- Template rendering will need a shard or custom implementation
- File watching and HTTP server are built into Crystal stdlib
