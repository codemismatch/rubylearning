# Typophic Crystal Port

This is the Crystal port of Typophic, a static site generator.

## Status

🚧 **Work in Progress** - Core structure is set up, migration in progress.

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

## Migration Progress

See [CRYSTAL_MIGRATION.md](../docs/CRYSTAL_MIGRATION.md) for detailed migration status.
