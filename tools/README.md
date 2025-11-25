# Typophic Development Tools

This directory contains development and testing utilities for the Typophic project.

## Active Tools

### [dev_watcher.cr](file:///Users/pankajdoharey/Development/rubylearning/tools/dev_watcher.cr)
Crystal-based file watcher for development. Monitors file changes and triggers rebuilds.

**Usage:**
```bash
crystal run tools/dev_watcher.cr
```

### [test_inline_rubocop.rb](file:///Users/pankajdoharey/Development/rubylearning/tools/test_inline_rubocop.rb)
Tests RuboCop integration for formatting inline Ruby code blocks.

**Usage:**
```bash
ruby tools/test_inline_rubocop.rb
```

### [verify_practice_inputs.py](file:///Users/pankajdoharey/Development/rubylearning/tools/verify_practice_inputs.py)
Python script for verifying practice input validation.

**Usage:**
```bash
python tools/verify_practice_inputs.py
```

## Integrated CLI Commands

The following utilities have been integrated into the main `typophic` CLI for easier access:

### Verify Chapter Integrity
Previously: `tools/verify_chapters.rb`  
Now: `bin/typophic verify [files]`

Runs solution/test blocks to verify chapter integrity.

**Example:**
```bash
bin/typophic verify content/pages/tutorials/ruby-symbols.md
```

### Format Tutorials
Previously: `tools/format_tutorials.rb`  
Now: `bin/typophic format`

Formats tutorial content.

**Example:**
```bash
bin/typophic format
```

### Check Pipeline Configuration
Previously: `tools/test_pipeline_config.rb`  
Now: `bin/typophic check_pipeline`

Tests your pipeline configuration.

**Example:**
```bash
bin/typophic check_pipeline
```

## Removed Tools

The following tools have been removed as they are no longer needed:

- **Migration tools**: `hugo_to_typophic_converter.rb`, `hugo_to_typophic_converter_v2.rb`, `convert_tutorials_to_new_format.rb` - One-time migration scripts
- **Redundant**: `normalize_quotes.rb` - Functionality built into `Typophic::Builder`
- **Test files**: `test_inline_rubocop_debug.rb`, `test_rubocop_api.rb`, `test_rubocop_runner.rb` - Development test scripts

If you need these in the future, they are available in git history.

## See Also

For a complete list of available commands, run:
```bash
bin/typophic help
```