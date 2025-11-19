#!/usr/bin/env ruby
# frozen_string_literal: true

require 'rubocop'
require 'tempfile'

test_code = <<~'RUBY'
  def hello(  name  )
    if name=='World'
  puts "Hello, #{name}!"
    end
  end

  arr=[1,2,3,4,5]
  hash={a: 1,b: 2,c: 3}
RUBY

puts "Original:"
puts test_code
puts "\n" + "=" * 60

Tempfile.create(['test', '.rb']) do |f|
  f.write(test_code)
  f.close
  
  puts "\nTemp file: #{f.path}"
  
  config_store = RuboCop::ConfigStore.new
  options = {
    autocorrect: true,
    safe_autocorrect: false,
    formatters: [['progress', $stdout]]
  }
  
  runner = RuboCop::Runner.new(options, config_store)
  puts "\nRunning RuboCop..."
  result = runner.run([f.path])
  
  puts "\nRunner result: #{result}"
  puts "\nCorrected content:"
  puts File.read(f.path)
end
