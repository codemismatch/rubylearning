# ProtoCss Tailwind Plugin

A comprehensive Tailwind CSS implementation for ProtoCss (PostCSS port in Ruby) with JIT mode, full variant support, and extensive utilities.

## Features

### 🚀 JIT Mode (Just-In-Time Compilation)
- Scans your content files to detect used classes
- Generates only the CSS you actually use
- Significantly smaller output files
- Faster build times
- File watching support for development

### 🎨 Complete Variant System
- **Responsive variants**: `sm:`, `md:`, `lg:`, `xl:`, `2xl:`
- **State variants**: `hover:`, `focus:`, `active:`, `visited:`, `disabled:`, `enabled:`, `checked:`
- **Group variants**: `group-hover:`, `group-focus:`, `group-active:`
- **Peer variants**: `peer-hover:`, `peer-focus:`, `peer-checked:`
- **Pseudo-class variants**: `first:`, `last:`, `odd:`, `even:`, `first-of-type:`, `last-of-type:`
- **Pseudo-element variants**: `before:`, `after:`, `placeholder:`, `selection:`, `marker:`
- **Dark mode**: `dark:` with class or media strategy
- **Stacked variants**: `md:hover:bg-blue-500`

### 🛠️ Comprehensive Utilities

#### Transforms
- Translate: `translate-x-*`, `translate-y-*`, `-translate-x-*`, `-translate-y-*`
- Rotate: `rotate-*`, `-rotate-*`
- Scale: `scale-*`, `scale-x-*`, `scale-y-*`
- Skew: `skew-x-*`, `skew-y-*`, `-skew-x-*`, `-skew-y-*`

#### Transitions & Animations
- Transition properties: `transition-*`, `duration-*`, `delay-*`, `ease-*`
- Animations: `animate-spin`, `animate-ping`, `animate-pulse`, `animate-bounce`

#### Filters & Effects
- Filters: `blur-*`, `brightness-*`, `contrast-*`, `grayscale`, `invert`, `sepia`
- Backdrop filters: `backdrop-blur-*`, `backdrop-brightness-*`, etc.
- Shadows: `shadow-sm`, `shadow-md`, `shadow-lg`, `shadow-xl`, `shadow-2xl`
- Opacity: `opacity-0` to `opacity-100` (steps of 5)

#### Layout & Positioning
- Z-index: `z-0`, `z-10`, `z-20`, `z-30`, `z-40`, `z-50`, `z-auto`
- Overflow: `overflow-*`, `overflow-x-*`, `overflow-y-*`
- Object fit: `object-contain`, `object-cover`, `object-fill`, etc.

#### Interactivity
- Cursor: `cursor-pointer`, `cursor-wait`, `cursor-not-allowed`, etc. (40+ cursors)
- Pointer events: `pointer-events-none`, `pointer-events-auto`
- Resize: `resize-none`, `resize-x`, `resize-y`, `resize`
- User select: `select-none`, `select-text`, `select-all`, `select-auto`

#### Accessibility
- Screen reader utilities: `sr-only`, `not-sr-only`

## Installation

Add to your Gemfile:

```ruby
gem 'protocss'
```

## Usage

### Basic Setup

```ruby
require 'protocss'
require 'protocss/plugins/tailwind'

# Create configuration
config = {
  mode: 'jit',  # or 'aot' for ahead-of-time
  content: [
    './app/views/**/*.html.erb',
    './app/javascript/**/*.js'
  ],
  darkMode: 'class',  # or 'media'
  theme: {
    extend: {
      colors: {
        'primary' => '#3b82f6'
      }
    }
  }
}

# Create Tailwind plugin
tailwind = Protocss::Plugins::Tailwind.new(config)

# Process CSS
css = '@tailwind base; @tailwind components; @tailwind utilities;'
processor = Protocss.new([tailwind])
result = processor.process(css)

puts result.css
```

### Configuration File

Create `tailwind.config.rb`:

```ruby
{
  mode: 'jit',
  
  content: [
    './app/**/*.html',
    './app/**/*.erb',
    './app/**/*.js'
  ],
  
  darkMode: 'class',
  
  safelist: [
    'bg-red-500',
    'text-center'
  ],
  
  theme: {
    screens: {
      'sm' => '640px',
      'md' => '768px',
      'lg' => '1024px',
      'xl' => '1280px',
      '2xl' => '1536px'
    },
    
    extend: {
      colors: {
        'brand' => '#ff6b6b'
      }
    }
  }
}
```

Then use it:

```ruby
tailwind = Protocss::Plugins::Tailwind.new('./tailwind.config.rb')
```

### JIT Mode vs AOT Mode

**JIT (Just-In-Time) Mode:**
- Scans your content files
- Generates only used classes
- Smaller output
- Requires `content` paths

```ruby
config = {
  mode: 'jit',
  content: ['./app/**/*.html']
}
```

**AOT (Ahead-Of-Time) Mode:**
- Generates all utilities upfront
- Applies common variants to all utilities
- Larger output but no content scanning needed

```ruby
config = {
  mode: 'aot'
}
```

### Using @apply

```css
.btn-primary {
  @apply px-6 py-3 bg-blue-500 text-white rounded-lg hover:bg-blue-600 transition-colors;
}
```

### Variant Examples

```html
<!-- Responsive -->
<div class="w-full md:w-1/2 lg:w-1/3">

<!-- Hover state -->
<button class="bg-blue-500 hover:bg-blue-600">

<!-- Dark mode -->
<div class="bg-white dark:bg-gray-800">

<!-- Combined variants -->
<div class="md:hover:bg-blue-500 dark:md:hover:bg-blue-600">

<!-- Group hover -->
<div class="group">
  <div class="group-hover:text-blue-500">
</div>
```

## Content Scanner

The content scanner automatically detects Tailwind classes in your files:

```ruby
scanner = Protocss::Plugins::Tailwind::ContentScanner.new([
  './app/**/*.html',
  './app/**/*.erb'
])

classes = scanner.scan
# => ["bg-blue-500", "text-white", "hover:bg-blue-600", ...]
```

### File Watching

Enable file watching for development:

```ruby
scanner = Protocss::Plugins::Tailwind::ContentScanner.new(
  ['./app/**/*.html'],
  watch: true
)

scanner.watch do |new_classes, removed_classes|
  puts "New classes: #{new_classes.join(', ')}"
  puts "Removed: #{removed_classes.join(', ')}"
  # Regenerate CSS
end
```

## Performance

### JIT Mode Benefits
- **Smaller CSS**: Only generates what you use
- **Faster builds**: No need to generate thousands of unused utilities
- **Better for production**: Optimized output size

### Ruby JIT Compilation
ProtoCss benefits from Ruby's YJIT/MJIT compilers for faster execution:

```bash
# Run with YJIT
ruby --yjit your_script.rb

# Or set environment variable
RUBY_YJIT_ENABLE=1 ruby your_script.rb
```

## Examples

See the `examples/` directory for:
- `demo.html` - Comprehensive demo showcasing all features
- `input.css` - Example input with @tailwind directives
- `tailwind.config.rb` - Example configuration
- `usage.rb` - Usage examples

Run the examples:

```bash
cd examples
ruby usage.rb
```

## Comparison with Official Tailwind

### What's Supported ✅
- JIT mode with content scanning
- All major utility categories
- Responsive variants
- State variants (hover, focus, etc.)
- Dark mode
- @apply directive
- Custom theme configuration

### What's Different ⚠️
- Written in pure Ruby (no Node.js required)
- Uses ProtoCss AST instead of PostCSS
- Some advanced features may differ
- Plugin ecosystem is separate

### What's Not Yet Supported ❌
- Official Tailwind plugins (@tailwindcss/forms, etc.)
- Arbitrary values (`bg-[#1da1f2]`)
- Container queries
- Some advanced variant combinations

## Contributing

Contributions are welcome! Areas for improvement:
- Additional utility coverage
- Performance optimizations
- More variant types
- Better error messages
- Test coverage

## License

MIT
