#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rubocop'

test_code = "arr=[1,2,3]"

processed = RuboCop::ProcessedSource.new(test_code, RUBY_VERSION.to_f, "(test)")
config_store = RuboCop::ConfigStore.new
config = config_store.for("(test)")
options = { autocorrect: true }

team = RuboCop::Cop::Team.mobilize(RuboCop::Cop::Registry.global, config, options)
report = team.investigate(processed)

puts "Offenses: #{report.offenses.size}"
puts "Report class: #{report.class}"
puts "Report methods with 'correct': #{report.methods.grep(/correct/).inspect}"

# Try the new API
if report.respond_to?(:corrected_source)
  puts "\n✅ Using report.corrected_source (new API)"
  puts report.corrected_source
elsif report.respond_to?(:correctors)
  puts "\n⚠️  Using report.correctors (old API)"
  puts report.correctors.inspect
end
