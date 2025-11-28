# frozen_string_literal: true

require "yaml"
require "fileutils"

module Typophic
  module Commands
    module Drafts
      def self.run(argv)
        subcommand = argv.shift

        case subcommand
        when "list", nil
          list_drafts(argv)
        else
          print_help
        end
      end

      def self.print_help
        puts <<~HELP
          Usage: typophic drafts <command>

          Commands:
            list        List all drafts across posts, tutorials, and pages

          Examples:
            typophic drafts list
        HELP
      end

      def self.list_drafts(argv)
        # Scan all draft locations
        draft_locations = [
          { type: "post", pattern: "content/drafts/*.md" },
          { type: "tutorial", pattern: "content/drafts/tutorials/*.md" },
          { type: "page", pattern: "content/drafts/pages/*.md" }
        ]

        # Also scan for files with draft: true in frontmatter
        published_with_draft_flag = [
          { type: "post", pattern: "content/posts/*.md" },
          { type: "tutorial", pattern: "content/pages/tutorials/*.md" },
          { type: "page", pattern: "content/pages/*.md" }
        ]

        drafts = []

        # Collect drafts from draft directories
        draft_locations.each do |loc|
          Dir.glob(loc[:pattern]).each do |path|
            next unless File.file?(path)
            
            metadata = extract_metadata(path)
            drafts << {
              type: loc[:type],
              path: path,
              title: metadata[:title],
              author: metadata[:author],
              modified: File.mtime(path)
            }
          end
        end

        # Collect files with draft: true
        published_with_draft_flag.each do |loc|
          Dir.glob(loc[:pattern]).each do |path|
            next unless File.file?(path)
            next if path.include?("/drafts/") # Skip already counted

            metadata = extract_metadata(path)
            next unless metadata[:draft]

            drafts << {
              type: loc[:type],
              path: path,
              title: metadata[:title],
              author: metadata[:author],
              modified: File.mtime(path)
            }
          end
        end

        if drafts.empty?
          puts "No drafts found."
          return
        end

        # Sort by type, then modified date
        drafts.sort_by! { |d| [d[:type], d[:modified]] }.reverse!

        # Display table
        puts "\n#{drafts.length} draft(s) found:\n\n"
        puts format("%-12s %-50s %-20s %s", "TYPE", "TITLE", "AUTHOR", "PATH")
        puts "-" * 120

        drafts.each do |draft|
          type_colored = colorize_type(draft[:type])
          title = truncate(draft[:title] || "Untitled", 48)
          author = truncate(draft[:author] || "Unknown", 18)
          path = draft[:path]
          
          puts format("%-12s %-50s %-20s %s", type_colored, title, author, path)
        end

        puts ""
      end

      def self.extract_metadata(path)
        content = File.read(path)
        metadata = { title: nil, author: nil, draft: false }

        if content.start_with?("---") && content =~ /^---\s*\n(.*?)\n---\s*\n/m
          fm_text = Regexp.last_match(1)
          begin
            fm = YAML.safe_load(fm_text) || {}
            metadata[:title] = fm["title"]
            metadata[:author] = fm["author"]
            metadata[:draft] = !!fm["draft"]
          rescue
            # Ignore parse errors
          end
        end

        metadata
      rescue
        metadata
      end

      def self.colorize_type(type)
        # Simple color coding using ANSI codes
        case type
        when "post"
          "\e[34m[#{type.upcase}]\e[0m"     # Blue
        when "tutorial"
          "\e[32m[#{type.upcase}]\e[0m"    # Green
        when "page"
          "\e[35m[#{type.upcase}]\e[0m"    # Magenta
        else
          "[#{type.upcase}]"
        end
      end

      def self.truncate(string, max_length)
        return string if string.length <= max_length
        "#{string[0...(max_length - 3)]}..."
      end
    end
  end
end
