# frozen_string_literal: true

require "optparse"
require "fileutils"
require "yaml"
require "pathname"
require "date"

require_relative "../theme_scaffolder"
require_relative "../util"
require_relative "blog"
require_relative "theme"

module Typophic
  module Commands
    module New
      DEFAULT_TYPE = "blog"

      def self.run(argv)
        sub = argv.first
        if ["-h", "--help", "help"].include?(sub)
          puts <<~HELP
            Usage:
              typophic new site NAME [--theme NAME|URL] [options]
              typophic new blog NAME [--theme NAME|URL] [options]
              typophic new post TITLE [--draft] [--tags a,b] [--author NAME]
              typophic new page TITLE [--permalink /path/] [--author NAME]

            Options (site/blog):
              --dir DIR            Target directory
              --type TYPE          Template type: blog, docs, ruby
              --author NAME        Author name for metadata (defaults to git config if present)
              --description TEXT   Site description
              --theme NAME|URL     Theme name or GitHub URL/OWNER/REPO

            Examples:
              typophic new site mysite --theme rubylearning
              typophic new blog myblog --theme https://github.com/user/theme
              typophic new post "Hello World" --tags intro --draft
              typophic new page "About" --permalink /about/
          HELP
          return
        end
        case sub
        when "site", "blog"
          argv.shift
          run_site(argv, type: sub == "blog" ? "blog" : "site")
        when "post"
          argv.shift
          run_post(argv)
        when "page"
          argv.shift
          run_page(argv)
        else
          # Back-compat: options-only site generator
          options = default_site_options
          site_parser(options).parse!(argv)
          options[:name] ||= "#{DEFAULT_TYPE}-site"
          options[:directory] ||= options[:name].gsub(/\s+/, "-").downcase
          options[:theme] ||= options[:directory]
          maybe_install_theme!(options)
          Generator.new(options).run
        end
      end

      def self.default_site_options
        {
          name: nil,
          directory: nil,
          type: DEFAULT_TYPE,
          author: Typophic::Util.resolved_author(fallback: "Typophic User"),
          description: "A beautiful static website",
          theme: nil
        }
      end

      def self.site_parser(options, banner: "Usage: typophic new site NAME [options]")
        OptionParser.new do |opts|
          opts.banner = banner

          opts.on("--dir DIR", "Target directory (defaults to sanitized name)") { |dir| options[:directory] = dir }
          opts.on("--type TYPE", "Template type: blog, docs, ruby") { |type| options[:type] = type }
          opts.on("--author AUTHOR", "Author name for metadata") { |author| options[:author] = author }
          opts.on("--description TEXT", "Site description") { |desc| options[:description] = desc }
          opts.on("--theme NAME|URL", "Theme name or GitHub URL/OWNER/REPO") { |theme| options[:theme] = theme }
          opts.on("-h", "--help", "Show this help message") { puts opts; exit }
        end
      end

      def self.run_site(argv, type: "site")
        options = default_site_options
        options[:type] = type
        parser = site_parser(options, banner: "Usage: typophic new #{type} NAME [options]")
        parser.parse!(argv)
        name = argv.shift
        if name.to_s.strip.empty?
          warn "NAME is required"
          puts parser
          exit 1
        end
        options[:name] = name
        options[:directory] ||= name.gsub(/\s+/, "-").downcase
        options[:theme] ||= options[:directory]
        maybe_install_theme!(options)
        Generator.new(options).run
      end

      def self.run_post(argv)
        # Positional title + options
        options = {
          title: nil, slug: nil, date: Date.today, tags: [], description: nil,
          layout: "post", draft: false, author: nil
        }
        parser = OptionParser.new do |opts|
          opts.banner = "Usage: typophic new post TITLE [options]"
          opts.on("--slug SLUG") { |v| options[:slug] = v }
          opts.on("--date DATE") { |v| options[:date] = Date.parse(v) }
          opts.on("--tags TAGS") { |v| options[:tags] = v.split(/\s*,\s*/).reject(&:empty?) }
          opts.on("--description TEXT") { |v| options[:description] = v }
          opts.on("--layout NAME") { |v| options[:layout] = v }
          opts.on("--draft") { options[:draft] = true }
          opts.on("--author NAME") { |v| options[:author] = v }
          opts.on("-h", "--help") { puts opts; exit }
        end
        # Peek for options then take remaining as title (first non-option)
        parser.order!(argv)
        title = argv.join(" ").strip
        if title.empty?
          warn "TITLE is required"
          puts parser
          exit 1
        end
        options[:title] = title
        options[:author] ||= Typophic::Util.resolved_author

        # Reuse blog implementation
        args = ["--title", options[:title]]
        args += ["--slug", options[:slug]] if options[:slug]
        args += ["--date", options[:date].strftime('%Y-%m-%d')]
        args += ["--tags", options[:tags].join(',')] if options[:tags]&.any?
        args += ["--description", options[:description]] if options[:description]
        args += ["--layout", options[:layout]] if options[:layout]
        args += ["--draft"] if options[:draft]
        args += ["--author", options[:author]] if options[:author]

        Typophic::Commands::Blog.create_post(args)
      end

      def self.run_page(argv)
        options = { permalink: nil, layout: "page", author: nil }
        parser = OptionParser.new do |opts|
          opts.banner = "Usage: typophic new page TITLE [options]"
          opts.on("--permalink PATH", "Custom permalink, e.g. /about/") { |v| options[:permalink] = v }
          opts.on("--layout NAME", "Layout to use (default: page)") { |v| options[:layout] = v }
          opts.on("--author NAME", "Author name for front matter") { |v| options[:author] = v }
          opts.on("-h", "--help", "Show help") { puts opts; exit }
        end
        parser.order!(argv)
        title = argv.join(" ").strip
        if title.empty?
          warn "TITLE is required"
          puts parser
          exit 1
        end
        slug = Typophic::Util.sanitize_slug(title)
        path = File.join("content", "pages", "#{slug}.md")
        if File.exist?(path)
          warn "Error: #{path} already exists"
          exit 1
        end
        fm = {
          "title" => title,
          "layout" => options[:layout],
          "permalink" => options[:permalink] || "/#{slug}/",
          "author" => (options[:author] || Typophic::Util.resolved_author)
        }.compact
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, format_front_matter(fm))
        puts "Created page: #{path}"
      end

      def self.format_front_matter(hash)
        yaml = hash.transform_keys(&:to_s).to_yaml(line_width: -1).sub(/^---\s*\n/, "").strip
        "---\n#{yaml}\n---\n\n"
      end

      def self.maybe_install_theme!(options)
        t = options[:theme].to_s
        return if t.empty?
        # If it's a URL or OWNER/REPO, install it and set theme name
        if t =~ %r{^https?://} || t =~ %r{^git@} || t.include?("/")
          installer = Typophic::Commands::Theme::Install.new([t])
          installer.run
          options[:theme] = File.basename(t.to_s.sub(/\.git\z/, "")) if options[:theme] == t
        end
      end

      class Generator
        attr_reader :options

        def initialize(options)
          @options = options
        end

        def run
          puts "Initializing Typophic site '#{options[:name]}' in #{root_path}"
          create_directories
          create_config
          create_content
          create_theme_files
          copy_runtime

          puts "\nSite initialized successfully!"
          puts "Next steps:"
          puts "  cd #{root_path}"
          puts "  typophic build"
          puts "  typophic serve --build"
        end

        private

        def root_path
          @root_path ||= File.expand_path(options[:directory])
        end

        def create_directories
          %w[
            bin
            content
            content/posts
            content/pages
            themes
            data
            public
          ].each do |path|
            absolute = File.join(root_path, path)
            FileUtils.mkdir_p(absolute)
            puts "Created directory: #{relative_path(absolute)}"
          end
        end

        def create_config
          config = {
            "site_name" => options[:name],
            "site_type" => options[:type],
            "author" => options[:author],
            "description" => options[:description],
            "url" => "http://example.com",
            "theme" => options[:theme],
            "permalink_style" => "pretty",
            "date_format" => "%B %-d, %Y",
            "markdown_extensions" => %w[tables fenced_code_blocks autolink]
          }

          write_file("config.yml", config.to_yaml)
        end

        def create_content
          write_file("content/pages/index.md", homepage_markdown)
          write_file("content/pages/about.md", about_markdown)
          write_file("content/posts/#{Time.now.strftime('%Y-%m-%d')}-welcome.md", welcome_markdown)

          case options[:type]
          when "docs"
            write_file("content/pages/documentation.md", documentation_markdown)
          when "ruby"
            write_file("content/posts/#{Time.now.strftime('%Y-%m-%d')}-ruby-examples.md", ruby_examples_markdown)
          end
        end

        def create_theme_files
          Typophic::ThemeScaffolder.generate(
            root_path: root_path,
            theme_name: options[:theme],
            site_name: options[:name],
            description: options[:description],
            author: options[:author]
          )
        end

        def copy_runtime
          source = File.expand_path("../../../bin/typophic", __dir__)
          target = File.join(root_path, "bin", "typophic")

          FileUtils.cp(source, target)
          FileUtils.chmod("u+x", target)
        rescue Errno::ENOENT
          warn "Warning: typophic binary not found for copying. Ensure this repository includes bin/typophic."
        end

        def write_file(relative, contents)
          absolute = File.join(root_path, relative)
          FileUtils.mkdir_p(File.dirname(absolute))
          File.write(absolute, contents)
          puts "Created file: #{relative_path(absolute)}"
        end

        def relative_path(path)
          Pathname.new(path).relative_path_from(Pathname.new(root_path)).to_s
        end

        def homepage_markdown
          <<~MARKDOWN
            ---
            title: Home
            layout: home
            permalink: /
            ---

            # Welcome to #{options[:name]}

            This site is powered by Typophic. Customize this page at `content/pages/index.md`.
          MARKDOWN
        end

        def about_markdown
          <<~MARKDOWN
        ---
        title: About
        layout: page
        permalink: /about/
        ---

            # About #{options[:name]}

            Built by #{options[:author]}. Update `content/pages/about.md` with your story.
          MARKDOWN
        end

        def welcome_markdown
          <<~MARKDOWN
            ---
            title: Welcome
            layout: post
            date: #{Time.now.strftime('%Y-%m-%d')}
            tags: [welcome]
            description: First post for #{options[:name]}
            ---

            Thanks for installing Typophic! Start editing content in the `content/` directory.
          MARKDOWN
        end

        def documentation_markdown
          <<~MARKDOWN
            ---
            title: Documentation
            layout: page
            ---

            # Documentation

            Provide onboarding steps and API references here.
          MARKDOWN
        end

        def ruby_examples_markdown
          <<~MARKDOWN
            ---
            title: Ruby Examples
            layout: post
            date: #{Time.now.strftime('%Y-%m-%d')}
            tags: [ruby, code]
            ---

            ```ruby
            puts "Hello from Typophic!"
            ```
          MARKDOWN
        end

      end
    end
  end
end
