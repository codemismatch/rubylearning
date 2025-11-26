#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/protocss'
require_relative '../lib/protocss/plugins/tailwind'

# Example 1: Using Tailwind with JIT Mode
puts "=== Example 1: JIT Mode ==="

config = {
  mode: 'jit',
  content: ['./examples/demo.html'],
  darkMode: 'class',
  theme: {
    extend: {
      colors: {
        'primary' => '#3b82f6'
      }
    }
  }
}

css = File.read('./examples/input.css')
tailwind_plugin = Protocss::Plugins::Tailwind.new(config)

processor = Protocss.new([tailwind_plugin])
result = processor.process(css, from: './examples/input.css')

puts "Generated CSS (first 500 chars):"
puts result.css[0..500]
puts "\n"

# Example 2: Using Tailwind with AOT Mode (All utilities)
puts "=== Example 2: AOT Mode ==="

config_aot = {
  mode: 'aot',
  darkMode: 'media'
}

tailwind_aot = Protocss::Plugins::Tailwind.new(config_aot)
processor_aot = Protocss.new([tailwind_aot])
result_aot = processor_aot.process(css, from: './examples/input.css')

puts "Generated utilities count: #{result_aot.root.nodes.length}"
puts "\n"

# Example 3: Content Scanner standalone usage
puts "=== Example 3: Content Scanner ==="

scanner = Protocss::Plugins::Tailwind::ContentScanner.new(['./examples/demo.html'])
classes = scanner.scan

puts "Found #{classes.length} unique classes:"
puts classes.first(20).join(', ')
puts "...\n\n"

# Example 4: Variant Generator standalone usage
puts "=== Example 4: Variant Generator ==="

variant_gen = Protocss::Plugins::Tailwind::VariantGenerator.new(config)

# Create a simple utility rule
base_rule = Protocss.rule(selector: '.bg-blue-500')
base_rule.append(Protocss.decl(prop: 'background-color', value: '#3b82f6'))

# Apply hover variant
hover_rule = variant_gen.apply_single_variant(base_rule, 'hover', 'bg-blue-500')
puts "Hover variant selector: #{hover_rule.selector}"

# Apply responsive variant
md_rule = variant_gen.apply_single_variant(base_rule, 'md', 'bg-blue-500')
puts "Responsive variant type: #{md_rule.type}"
puts "Media query: #{md_rule.params}" if md_rule.type == 'atrule'

puts "\n=== All Examples Complete ==="
