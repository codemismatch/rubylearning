# frozen_string_literal: true

require "cgi"
require "fileutils"

module Typophic
  # Normalizes Ruby code fences in tutorial markdown into the HTML structure
  # expected by Typophic's code window renderer. Used both during manual tooling
  # (via tools/format_tutorials.rb) and automatically as part of the build.
  module TutorialFormatter
    OPENERS   = %w[class module def begin case if unless while until for do].freeze
    CLOSERS   = %w[end].freeze
    MID_BLOCK = %w[else elsif when rescue ensure].freeze

    # Format every tutorial markdown file under content/pages/tutorials.
    #
    # @param root [String] project root used to resolve content directory
    # @param backup [Boolean] whether to write .bak files before modifying
    # @return [Array<String>] list of files that were rewritten
    def self.format_all(root: Dir.pwd, backup: false)
      tutorials_dir = File.join(root, "content", "pages", "tutorials")
      return [] unless Dir.exist?(tutorials_dir)

      Dir.glob(File.join(tutorials_dir, "*.md")).sort.filter_map do |path|
        transform_file(path, backup: backup) ? path : nil
      end
    end

    # Rewrites ruby fences in +input+ and returns the transformed string.
    #
    # @param input [String]
    # @return [String]
    def self.transform_content(input)
      input.gsub(/```(ruby-exec|ruby)\n(.*?)```/m) do
        language = Regexp.last_match(1)
        body = format_ruby(Regexp.last_match(2).rstrip)
        escaped = CGI.escapeHTML(body)

        if language == "ruby-exec"
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
    end

    # Formats Ruby code with simple indentation heuristics.
    #
    # @param code [String]
    # @return [String]
    def self.format_ruby(code)
      indent = 0
      code.each_line.map do |raw|
        stripped = raw.rstrip
        content = stripped.strip

        if content.empty?
          ""
        else
          keyword = content.split("#", 2).first&.strip

          if keyword && keyword.match?(/^(#{(CLOSERS + MID_BLOCK).join("|")})\b/)
            indent = [indent - 1, 0].max
          end

          line = ("  " * indent) + content

          if keyword
            if keyword.match?(/^(#{OPENERS.join("|")})\b/) || keyword.match?(/\bdo\b(?:\s*\|.*\|)?\s*(#.*)?$/)
              indent += 1
            elsif keyword.match?(/^(#{MID_BLOCK.join("|")})\b/)
              indent += 1
            end
          end

          line
        end
      end.join("\n").gsub(/\n{3,}/, "\n\n").sub(/\A\n+/, "").sub(/\n+\z/, "\n")
    end

    def self.transform_file(path, backup:)
      original = File.read(path)
      changed = transform_content(original)
      return false if changed == original

      FileUtils.cp(path, "#{path}.bak") if backup
      File.write(path, changed)
      true
    end

    private_class_method :format_ruby, :transform_file
  end
end

