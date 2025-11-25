# Typophic Crystal Port

This is the Crystal port of Typophic, a static site generator.

## Status

✅ **Complete** - The Crystal port is fully functional with feature parity to the Ruby version.

## Building

```bash
# Install Crystal (macOS)
brew install crystal

# Install dependencies
shards install

# Build
crystal build src/bin/typophic.cr -o bin/typophic --release

# Run
./bin/typophic help
```

## Development

```bash
# Run without building
crystal run src/bin/typophic.cr -- help

# Run with debugging
crystal run --debug src/bin/typophic.cr -- help
```

## Features

The Crystal implementation supports all major features:
- Build and serve commands
- Content processing pipeline
- Practice blocks and executable code
- Live reload
- Parallel processing
- File watching

See the main project [README](../README.md) and [documentation](../docs/) for usage guides.
