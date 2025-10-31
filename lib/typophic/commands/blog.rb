# frozen_string_literal: true

require "optparse"
require "fileutils"
require "yaml"
require "date"

module Typophic
  module Commands
    module Blog
      DEFAULT_LAYOUT = "post"
      POSTS_DIR = File.join("content", "posts")
      DRAFTS_DIR = File.join("content", "drafts")

      def self.run(argv)
        subcommand = argv.shift

        case subcommand
        when "new"
          create_post(argv)
        when "publish"
          publish_post(argv)
        else
          print_help
        end
      end

      def self.print_help
        puts <<~HELP
          Usage: typophic blog <command> [options]

          Commands:
            new       Create a new blog article (draft or published)
            publish   Move a draft into posts and refresh its date

          Examples:
            typophic blog new --title "Understanding Enumerable"
            typophic blog new --title "Rails smoke tests" --tags "rails,testing" --draft
            typophic blog publish --slug rails-smoke-tests
        HELP
      end

      def self.create_post(argv)
        options = {
          title: nil,
          slug: nil,
          date: Date.today,
          tags: [],
          description: nil,
          layout: DEFAULT_LAYOUT,
          draft: false
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

        FileUtils.mkdir_p(POSTS_DIR)
        FileUtils.mkdir_p(DRAFTS_DIR)

        path = if options[:draft]
          File.join(DRAFTS_DIR, "#{slug}.md")
        else
          File.join(POSTS_DIR, "#{options[:date].strftime('%Y-%m-%d')}-#{slug}.md")
        end

        if File.exist?(path)
          warn "Error: #{path} already exists"
          exit 1
        end

        front_matter = {
          "title" => options[:title],
          "layout" => options[:layout],
          "date" => options[:date].strftime("%Y-%m-%d"),
          "description" => options[:description],
          "tags" => options[:tags]
        }.compact

        File.write(path, format_post(front_matter))

        puts "Created #{options[:draft] ? 'draft' : 'post'}: #{path}"
      end

      def self.publish_post(argv)
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

        front_matter, body = read_post(draft_path)
        front_matter["date"] = options[:date].strftime("%Y-%m-%d")

        FileUtils.mkdir_p(POSTS_DIR)
        target = File.join(POSTS_DIR, "#{options[:date].strftime('%Y-%m-%d')}-#{options[:slug]}.md")

        File.write(target, format_post(front_matter, body))
        FileUtils.rm_f(draft_path)

        puts "Published post: #{target}"
      end

      def self.parser_for_new(options)
        OptionParser.new do |opts|
          opts.banner = "Usage: typophic blog new [options]"

          opts.on("--title TITLE", "Post title") { |title| options[:title] = title }
          opts.on("--slug SLUG", "Custom slug (defaults to parameterized title)") { |slug| options[:slug] = slug }
          opts.on("--date DATE", "Publish date (YYYY-MM-DD)") { |date| options[:date] = Date.parse(date) }
          opts.on("--tags TAGS", "Comma-separated tags") { |tags| options[:tags] = tags.split(/\s*,\s*/).reject(&:empty?) }
          opts.on("--description TEXT", "Short description for the front matter") { |desc| options[:description] = desc }
          opts.on("--layout NAME", "Layout to use (default: #{DEFAULT_LAYOUT})") { |layout| options[:layout] = layout }
          opts.on("--draft", "Create the post under content/drafts") { options[:draft] = true }
          opts.on("-h", "--help", "Show this help message") do
            puts opts
            exit
          end
        end
      end

      def self.parser_for_publish(options)
        OptionParser.new do |opts|
          opts.banner = "Usage: typophic blog publish [options]"

          opts.on("--slug SLUG", "Slug of the draft to publish") { |slug| options[:slug] = slug }
          opts.on("--date DATE", "Override publish date (YYYY-MM-DD)") { |date| options[:date] = Date.parse(date) }
          opts.on("-h", "--help", "Show this help message") do
            puts opts
            exit
          end
        end
      end

      def self.format_post(front_matter, body = "")
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

      def self.read_post(path)
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
