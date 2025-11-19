#!/usr/bin/env ruby
# frozen_string_literal: true

# Detailed test script for InlineRuboCop with debugging

require_relative "../lib/typophic/inline_rubocop"

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
puts "TESTING InlineRuboCop (DEBUG MODE)"
puts "=" * 60
puts "\nRuboCop version: #{RuboCop::Version::STRING}"
puts "Ruby version: #{RUBY_VERSION}"

puts "\n📝 Original Code:"
puts "-" * 60
puts test_code
puts "-" * 60

begin
  # Create a detailed test
  processed = RuboCop::ProcessedSource.new(
    test_code,
    RUBY_VERSION.to_f,
    "(test)"
  )

  puts "\n🔍 Parser Analysis:"
  puts "  Parser error: #{processed.parser_error || 'None'}"
  puts "  Valid syntax: #{!processed.parser_error}"
  
  config_store = RuboCop::ConfigStore.new
  config = config_store.for("(test)")
  
  puts "\n⚙️  RuboCop Configuration:"
  puts "  Config loaded: #{config ? 'Yes' : 'No'}"
  
  options = { autocorrect: true }
  team = RuboCop::Cop::Team.mobilize(
    RuboCop::Cop::Registry.global,
    config,
    options
  )
  
  puts "\n🚓 Running RuboCop cops..."
  report = team.investigate(processed)
  
  puts "\n📊 Report Summary:"
  puts "  Offenses found: #{report.offenses.size}"
  
  if report.offenses.any?
    puts "\n  Offenses:"
    report.offenses.first(5).each do |offense|
      puts "    - #{offense.cop_name}: #{offense.message}"
      puts "      Line #{offense.line}: #{offense.correctable? ? '[Auto-correctable]' : '[Manual]'}"
    end
  end
  
  correctors = report.correctors
  puts "\n  Correctors available: #{correctors.size}"
  
  if correctors.any?
    formatted = correctors.last.rewrite
    puts "\n✨ Formatted Code:"
    puts "-" * 60
    puts formatted
    puts "-" * 60
    
    if formatted != test_code
      puts "\n✅ SUCCESS: Code was auto-corrected!"
    else
      puts "\n⚠️  WARNING: Correctors ran but code unchanged."
    end
  else
    puts "\n⚠️  No correctors were generated."
    puts "   This might mean:"
    puts "   1. RuboCop found no auto-correctable issues"
    puts "   2. Auto-correct is disabled in config"
    puts "   3. The RuboCop API changed"
  end
  
rescue StandardError => e
  puts "\n❌ ERROR: #{e.class}"
  puts "   #{e.message}"
  puts "\n   Backtrace:"
  puts e.backtrace.first(10).map { |line| "     #{line}" }
  exit 1
end

puts "\n" + "=" * 60
