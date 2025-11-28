# frozen_string_literal: true

require "optparse"
require "fileutils"
require "yaml"
require "date"
require_relative "../util"

module Typophic
  module Commands
    module Tutorial
      TUTORIALS_DIR = File.join("content", "pages", "tutorials")
      DRAFTS_DIR = File.join("content", "drafts", "tutorials")

      def self.run(argv)
        subcommand = argv.shift

        case subcommand
        when "new"
          create_tutorial(argv)
        when "publish"
          publish_tutorial(argv)
        when "list"
          list_tutorials(argv)
        else
          print_help
        end
      end

      def self.print_help
        puts <<~HELP
          Usage: typophic tutorial <command> [options]

          Commands:
            new         Create a new tutorial (draft or published)
            publish     Move a draft tutorial to published
            list        List tutorials (and drafts with --drafts)

          Examples:
            typophic tutorial new "Ruby Basics" --draft
            typophic tutorial new "Advanced SQL" --author "Jane Doe"
            typophic tutorial publish --slug ruby-basics
        HELP
      end

      def self.create_tutorial(argv)
        options = {
          title: nil,
          slug: nil,
          date: Date.today,
          description: nil,
          layout: "tutorial",
          draft: false,
          author: nil,
          permalink: nil,
          difficulty: "beginner"
        }

        parser_for_new(options).parse!(argv)

        if options[:title].to_s.strip.empty?
          warn "Error: --title is required"
          exit 1
        end

        slug = (options[:slug] || options[:title]).downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
        if slug.empty?
          warn "Error: unable to derive slug from title"
          exit 1
        end

        FileUtils.mkdir_p(TUTORIALS_DIR)
        FileUtils.mkdir_p(DRAFTS_DIR)

        path = if options[:draft]
          File.join(DRAFTS_DIR, "#{slug}.md")
        else
          File.join(TUTORIALS_DIR, "#{slug}.md")
        end

        if File.exist?(path)
          warn "Error: #{path} already exists"
          exit 1
        end

        author_value = options[:author] || Typophic::Util.resolved_author
        permalink = options[:permalink] || "/tutorials/#{slug}/"
        
        front_matter = {
          "layout" => options[:layout],
          "title" => options[:title],
          "permalink" => permalink,
          "difficulty" => options[:difficulty],
          "summary" => options[:description],
          "date" => options[:date].strftime("%Y-%m-%d"),
          "author" => author_value
        }
        
        front_matter["draft"] = true if options[:draft]
        front_matter.compact!

        File.write(path, format_tutorial(front_matter))

        puts "Created #{options[:draft] ? 'draft' : ''} tutorial: #{path}"
      end

      def self.publish_tutorial(argv)
        options = {
          slug: nil,
          date: Date.today
        }

        parser_for_publish(options).parse!(argv)

        if options[:slug].to_s.strip.empty?
          warn "Error: --slug is required"
          exit 1
        end

        draft_path = File.join(DRAFTS_DIR, "#{options[:slug]}.md")
        unless File.exist?(draft_path)
          warn "Error: draft not found at #{draft_path}"
          exit 1
        end

        front_matter, body = read_tutorial(draft_path)
        front_matter["date"] = options[:date].strftime("%Y-%m-%d")
        front_matter.delete("draft")

        FileUtils.mkdir_p(TUTORIALS_DIR)
        target = File.join(TUTORIALS_DIR, "#{options[:slug]}.md")

        if File.exist?(target)
          warn "Error: #{target} already exists"
          exit 1
        end

        File.write(target, format_tutorial(front_matter, body))
        FileUtils.rm_f(draft_path)

        puts "Published tutorial: #{target}"
      end

      def self.list_tutorials(argv)
        options = { drafts: false }
        parser = OptionParser.new do |opts|
          opts.banner = "Usage: typophic tutorial list [--drafts]"
          opts.on("--drafts", "Include drafts") { options[:drafts] = true }
          opts.on("-h", "--help", "Show help") { puts opts; exit }
        end
        parser.parse!(argv)

        tutorials = Dir.glob(File.join(TUTORIALS_DIR, "*.md")).sort
        drafts = options[:drafts] ? Dir.glob(File.join(DRAFTS_DIR, "*.md")).sort : []

        (tutorials + drafts).each do |path|
          title = begin
            fm, _ = read_tutorial(path)
            fm["title"] || File.basename(path)
          rescue
            File.basename(path)
          end
          status = path.include?("/drafts/") ? "[DRAFT]" : ""
          puts "#{path}\t#{status} #{title}"
        end
      end

      def self.parser_for_new(options)
        OptionParser.new do |opts|
          opts.banner = "Usage: typophic tutorial new [options]"

          opts.on("--title TITLE", "Tutorial title") { |title| options[:title] = title }
          opts.on("--slug SLUG", "Custom slug (defaults to parameterized title)") { |slug| options[:slug] = slug }
          opts.on("--date DATE", "Publish date (YYYY-MM-DD)") { |date| options[:date] = Date.parse(date) }
          opts.on("--description TEXT", "Short description/summary") { |desc| options[:description] = desc }
          opts.on("--difficulty LEVEL", "Difficulty: beginner, intermediate, advanced") { |d| options[:difficulty] = d }
          opts.on("--permalink PATH", "Custom permalink") { |p| options[:permalink] = p }
          opts.on("--draft", "Create as draft under content/drafts/tutorials") { options[:draft] = true }
          opts.on("--author NAME", "Author name for front matter") { |a| options[:author] = a }
          opts.on("-h", "--help", "Show this help message") do
            puts opts
            exit
          end
        end
      end

      def self.parser_for_publish(options)
        OptionParser.new do |opts|
          opts.banner = "Usage: typophic tutorial publish [options]"

          opts.on("--slug SLUG", "Slug of the draft to publish") { |slug| options[:slug] = slug }
          opts.on("--date DATE", "Override publish date (YYYY-MM-DD)") { |date| options[:date] = Date.parse(date) }
          opts.on("-h", "--help", "Show this help message") do
            puts opts
            exit
          end
        end
      end

      def self.format_tutorial(front_matter, body = "")
        fm = front_matter.transform_keys(&:to_s)
        yaml = fm.to_yaml(line_width: -1).sub(/^---\s*\n/, "").strip
        body = body.to_s.lstrip

        output = String.new("---\n")
        output << yaml
        output << "\n---\n"
        output << "\n" unless body.empty?
        output << body
        output << "\n" unless output.end_with?("\n")
        output
      end

      def self.read_tutorial(path)
        content = File.read(path)
        unless content.start_with?("---")
          warn "Error: #{path} lacks front matter"
          exit 1
        end

        unless content =~ /^---\s*\n(.*?)\n---\s*\n/m
          warn "Error: unable to parse front matter in #{path}"
          exit 1
        end

        fm_text = Regexp.last_match(1)
        body_start = Regexp.last_match.end(0)
        body = content[body_start..] || ""
        [YAML.safe_load(fm_text) || {}, body]
      end
    end
  end
end
