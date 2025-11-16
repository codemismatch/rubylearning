#!/usr/bin/env ruby
# frozen_string_literal: true

# tools/normalize_quotes.rb
#
# Scans all Markdown content and normalizes “smart” quotes and similar
# characters into plain ASCII so they render consistently in HTML.
#
# Intended usage:
#   - Manually: ruby tools/normalize_quotes.rb
#   - Automatically: invoked by Typophic::Builder during builds.

require "fileutils"

ROOT = File.expand_path("..", __dir__)

SMART_MAP = {
  # Double quotes
  "\u201C" => '"', # LEFT DOUBLE QUOTATION MARK
  "\u201D" => '"', # RIGHT DOUBLE QUOTATION MARK
  # Single quotes / apostrophes
  "\u2018" => "'", # LEFT SINGLE QUOTATION MARK
  "\u2019" => "'", # RIGHT SINGLE QUOTATION MARK
  # Dashes
  "\u2013" => "-", # EN DASH
  "\u2014" => "-", # EM DASH
}.freeze

TARGET_EXTENSIONS = [".md", ".markdown"].freeze

def normalize_file(path)
  original = File.read(path, mode: "r:BOM|UTF-8")
  normalized = original.dup

  SMART_MAP.each do |from, to|
    normalized.gsub!(from, to)
  end

  return false if normalized == original

  File.write(path, normalized)
  true
rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError => e
  warn "Skipping #{path} due to encoding error: #{e.message}"
  false
end

def main
  content_root = File.join(ROOT, "content")
  changed = []

  Dir.glob(File.join(content_root, "**", "*")).each do |path|
    next unless File.file?(path)

    ext = File.extname(path).downcase
    next unless TARGET_EXTENSIONS.include?(ext)

    changed << path if normalize_file(path)
  end

  if changed.empty?
    puts "No smart quotes or dashes needed normalization."
  else
    changed.each { |p| puts "Normalized quotes in: #{p.sub("#{ROOT}/", "")}" }
  end
end

main if $PROGRAM_NAME == __FILE__

