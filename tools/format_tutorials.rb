#!/usr/bin/env ruby
# frozen_string_literal: true

require 'fileutils'
require 'cgi'

ROOT = File.expand_path('..', __dir__)
TUTORIALS_DIR = File.join(ROOT, 'content', 'pages', 'tutorials')

OPENERS   = %w[class module def begin case if unless while until for do].freeze
CLOSERS   = %w[end].freeze
MID_BLOCK = %w[else elsif when rescue ensure].freeze

def format_ruby(code)
  lines = code.split("\n")
  indent = 0
  out = []

  lines.each do |raw|
    stripped = raw.rstrip
    content = stripped.strip

    if content.empty?
      out << ''
      next
    end

    keyword = content.split('#', 2).first&.strip

    if keyword && keyword =~ /^(#{(CLOSERS + MID_BLOCK).join('|')})\b/
      indent = [indent - 1, 0].max
    end

    out << ('  ' * indent) + content

    if keyword
      if keyword =~ /^(#{OPENERS.join('|')})\b/ || keyword =~ /\bdo\b(?:\s*\|.*\|)?\s*(#.*)?$/
        indent += 1
      elsif keyword =~ /^(#{MID_BLOCK.join('|')})\b/
        indent += 1
      end
    end
  end

  out.join("\n").gsub(/\n{3,}/, "\n\n").sub(/\A\n+/, '').sub(/\n+\z/, "\n")
end

def transform_file(path)
  original = File.read(path)
  changed = original.dup
  # Handle both ```ruby-exec and ```ruby fences
  changed.gsub!(/```(ruby-exec|ruby)\n(.*?)```/m) do
    lang = Regexp.last_match(1)
    body = Regexp.last_match(2)
    formatted = format_ruby(body.rstrip)
    escaped = CGI.escapeHTML(formatted)
    if lang == 'ruby-exec'
      <<~HTML.chomp
      <pre class="language-ruby" data-executable="true" contenteditable="true" style="white-space: pre-wrap; outline: none;"><code class="ruby-exec language-ruby">
      #{escaped}
      </code></pre>
      HTML
    else
      <<~HTML.chomp
      <pre class="language-ruby"><code class="language-ruby">
      #{escaped}
      </code></pre>
      HTML
    end
  end

  return false if changed == original

  backup = path + '.bak'
  FileUtils.cp(path, backup)
  File.write(path, changed)
  true
end

def main
  Dir.glob(File.join(TUTORIALS_DIR, '*.md')).sort.each do |md|
    changed = transform_file(md)
    puts(changed ? "Formatted: #{md}" : "Unchanged: #{md}")
  end
end

main if __FILE__ == $PROGRAM_NAME
