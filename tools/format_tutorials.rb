#!/usr/bin/env ruby
# frozen_string_literal: true

require_relative "../lib/typophic/tutorial_formatter"

ROOT = File.expand_path("..", __dir__)

def main
  changed = Typophic::TutorialFormatter.format_all(root: ROOT, backup: true)

  if changed.empty?
    puts "No tutorial files required formatting."
  else
    changed.each { |path| puts "Formatted: #{path}" }
  end
end

main if __FILE__ == $PROGRAM_NAME
