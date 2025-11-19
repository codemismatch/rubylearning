#!/usr/bin/env ruby
# frozen_string_literal: true

# Test script for InlineRuboCop

require_relative "../lib/typophic/inline_rubocop"

# Test code with intentional formatting issues
test_code = <<~'RUBY'
  def hello(  name  )
    if name=='World'
  puts "Hello, #{name}!"
    end
  end

  arr=[1,2,3,4,5]
  hash={a: 1,b: 2,c: 3}
RUBY

puts "=" * 60
puts "TESTING InlineRuboCop"
puts "=" * 60

puts "\n📝 Original Code (poorly formatted):"
puts "-" * 60
puts test_code
puts "-" * 60

begin
  formatter = Typophic::InlineRuboCop.instance
  formatted = formatter.format(test_code, file: "(test)")
  
  puts "\n✨ Formatted Code (after RuboCop):"
  puts "-" * 60
  puts formatted
  puts "-" * 60
  
  if formatted != test_code
    puts "\n✅ SUCCESS: RuboCop formatting is working!"
    puts "   Code was automatically corrected."
  else
    puts "\n⚠️  WARNING: RuboCop didn't make any changes."
    puts "   Either the code is already perfect or RuboCop isn't working."
  end
  
rescue LoadError => e
  puts "\n❌ ERROR: RuboCop gem not found!"
  puts "   #{e.message}"
  puts "\n   Run: bundle install"
  exit 1
rescue StandardError => e
  puts "\n❌ ERROR: #{e.class}"
  puts "   #{e.message}"
  puts "\n   Backtrace:"
  puts e.backtrace.first(5).map { |line| "     #{line}" }
  exit 1
end

puts "\n" + "=" * 60
puts "Test completed!"
puts "=" * 60
