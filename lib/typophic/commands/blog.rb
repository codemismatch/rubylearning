# frozen_string_literal: true

require "optparse"
require "fileutils"
require "yaml"
require "date"
require_relative "../util"

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
        when "list"
          list_posts(argv)
        when "delete", "rm"
          delete_post(argv)
        else
          print_help
        end
      end

      def self.print_help
        puts <<~HELP
          Usage: typophic blog <command> [options]

          Commands:
            new         Create a new blog article (draft or published)
            publish     Move a draft into posts and refresh its date
            list        List posts (and drafts with --drafts)
            delete|rm   Delete a post or draft by slug/date

          Examples:
            typophic blog new --title "Understanding Enumerable"
            typophic blog new --title "Rails smoke tests" --tags "rails,testing" --draft --author "Jane Doe"
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
          draft: false,
          author: nil
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

        author_value = options[:author] || Typophic::Util.resolved_author
        front_matter = {
          "title" => options[:title],
          "layout" => options[:layout],
          "date" => options[:date].strftime("%Y-%m-%d"),
          "description" => options[:description],
          "tags" => options[:tags],
          "author" => author_value
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
          opts.on("--author NAME", "Author name for front matter") { |a| options[:author] = a }
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

      def self.list_posts(argv)
        options = { drafts: false }
        parser = OptionParser.new do |opts|
          opts.banner = "Usage: typophic blog list [--drafts]"
          opts.on("--drafts", "Include drafts") { options[:drafts] = true }
          opts.on("-h", "--help", "Show help") { puts opts; exit }
        end
        parser.parse!(argv)

        posts = Dir.glob(File.join(POSTS_DIR, "*.md")).sort
        drafts = options[:drafts] ? Dir.glob(File.join(DRAFTS_DIR, "*.md")).sort : []

        (posts + drafts).each do |path|
          title = begin
            fm, _ = read_post(path)
            fm["title"] || File.basename(path)
          rescue
            File.basename(path)
          end
          puts "#{path}\t#{title}"
        end
      end

      def self.delete_post(argv)
        options = { slug: nil, draft: false, date: nil }
        parser = OptionParser.new do |opts|
          opts.banner = "Usage: typophic blog delete --slug SLUG [--draft] [--date YYYY-MM-DD]"
          opts.on("--slug SLUG", "Slug of the post/draft") { |s| options[:slug] = s }
          opts.on("--draft", "Delete from drafts rather than posts") { options[:draft] = true }
          opts.on("--date DATE", "Date of the post (for posts dir)") { |d| options[:date] = Date.parse(d) }
          opts.on("-h", "--help", "Show help") { puts opts; exit }
        end
        parser.parse!(argv)
        if options[:slug].to_s.strip.empty?
          warn "Error: --slug is required"
          exit 1
        end
        path = if options[:draft]
          File.join(DRAFTS_DIR, "#{options[:slug]}.md")
        else
          if options[:date].nil?
            # Best-effort: find matching post by slug
            candidates = Dir.glob(File.join(POSTS_DIR, "*-#{options[:slug]}.md"))
            path = candidates.sort.last
          else
            File.join(POSTS_DIR, "#{options[:date].strftime('%Y-%m-%d')}-#{options[:slug]}.md")
          end
        end
        if path && File.exist?(path)
          FileUtils.rm_f(path)
          puts "Deleted #{path}"
        else
          warn "Not found: #{path || 'unknown'}"
          exit 1
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
