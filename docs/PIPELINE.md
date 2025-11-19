# Content Processing Pipeline

## Overview

The Typophic content processing pipeline transforms your Markdown and code blocks through a series of configurable steps before final rendering.

## Configuration

### Method 1: config.yml (Recommended)

Add a `pipeline` section to your `config.yml`:

```yaml
pipeline:
  steps:
  - rubocop_ruby_blocks  # Auto-format Ruby code blocks with RuboCop
  - hash_blocks          # Process #> ... #! style blocks
  - ruby_exec            # Process ```ruby-exec blocks
  - markdown             # Convert Markdown to HTML
```

### Method 2: Pipelinefile (Legacy)

Create a `Pipelinefile` in your project root:

```ruby
content %w[
  rubocop_ruby_blocks
  hash_blocks
  ruby_exec
  markdown
]
```

**Note:** `config.yml` takes precedence over `Pipelinefile`.

## Available Pipeline Steps

### 1. `rubocop_ruby_blocks`

Auto-formats Ruby code blocks using RuboCop.

**Syntax:**
```markdown
#> ruby: format
def messy_code(  x  )
  puts"hello"
end
#!
```

**Output:** Beautifully formatted Ruby code with proper spacing, style, and conventions.

**Features:**
- Fixes spacing and indentation
- Applies Ruby style guide conventions
- Converts complex conditionals to guard clauses
- Adds `frozen_string_literal` pragmas

### 2. `hash_blocks`

Processes hash-delimited code blocks (`#> ... #!`).

**Syntax:**
```markdown
#> ruby: run
puts "This code will be runnable"
#!

#> javascript
console.log('Syntax highlighting only');
#!
```

**Options:**
- `run` - Makes the code block executable in the browser

### 3. `ruby_exec`

Processes special ` ```ruby-exec ` markdown code blocks.

**Syntax:**
````markdown
```ruby-exec
puts "This will be executable"
```
````

**Output:** Interactive Ruby code block with a "Run" button.

### 4. `markdown`

Converts Markdown to HTML using your configured extensions.

## Pipeline Order

Steps run in the order specified. Typical order:

1. **rubocop_ruby_blocks** - Format Ruby first (before syntax highlighting)
2. **hash_blocks** - Process special block syntax
3. **ruby_exec** - Add execution capabilities
4. **markdown** - Final conversion to HTML

## Testing

Test your pipeline configuration:

```bash
ruby tools/test_pipeline_config.rb
```

Test RuboCop formatting:

```bash
ruby tools/test_inline_rubocop.rb
```

## Customization

You can customize which steps run by modifying the `steps` array in `config.yml`:

```yaml
# Minimal pipeline (no RuboCop formatting)
pipeline:
  steps:
  - hash_blocks
  - markdown

# Custom order
pipeline:
  steps:
  - markdown          # Process Markdown first
  - ruby_exec         # Then add executability
  - rubocop_ruby_blocks  # Format last (unusual but possible)
```

## Adding Custom Pipeline Steps

1. Define a method in `lib/typophic/builder.rb`:
   ```ruby
   def pipeline_my_custom_step(content, page)
     # Transform content here
     content.gsub(/PATTERN/, 'REPLACEMENT')
   end
   ```

2. Add it to `config.yml`:
   ```yaml
   pipeline:
     steps:
     - my_custom_step
     - markdown
   ```

## Troubleshooting

### RuboCop not formatting

1. Check RuboCop is installed: `bundle exec rubocop --version`
2. Verify the `format` option is used: `#> ruby: format`
3. Run test: `ruby tools/test_inline_rubocop.rb`

### Pipeline not running

1. Check configuration: `ruby tools/test_pipeline_config.rb`
2. Verify YAML syntax in `config.yml`
3. Check logs during build

### Changes not appearing

The pipeline runs during site build. Make sure you're running:
```bash
bundle exec typophic build
```

Or using the watch server:
```bash
bundle exec typophic serve --build --watch
```
