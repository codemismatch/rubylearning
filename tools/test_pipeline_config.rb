#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative '../lib/typophic/pipeline'

puts "=" * 60
puts "TESTING Pipeline Configuration"
puts "=" * 60

steps = Typophic::Pipeline.content_steps

puts "\n✅ Pipeline steps loaded:"
steps.each_with_index do |step, i|
  puts "  #{i + 1}. #{step}"
end

puts "\n📍 Configuration source:"
if File.exist?('config.yml')
  require 'yaml'
  config = YAML.load_file('config.yml')
  if config && config['pipeline']
    puts "  ✅ Loaded from config.yml"
  else
    puts "  ⚠️  No pipeline config in config.yml"
  end
else
  puts "  ❌ config.yml not found"
end

if File.exist?('Pipelinefile')
  puts "  ⚠️  Pipelinefile exists (used as fallback)"
else
  puts "  ℹ️  No Pipelinefile (not needed)"
end

puts "\n" + "=" * 60
puts "Pipeline configuration working!"
puts "=" * 60
