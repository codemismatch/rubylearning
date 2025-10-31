# frozen_string_literal: true

require "optparse"
require "fileutils"
require "yaml"
require "pathname"

require_relative "../theme_scaffolder"

module Typophic
  module Commands
    module New
      DEFAULT_TYPE = "blog"

      def self.run(argv)
        options = {
          name: nil,
          directory: nil,
          type: DEFAULT_TYPE,
          author: "Typophic User",
          description: "A beautiful static website",
          theme: nil
        }

        parser(options).parse!(argv)
        options[:name] ||= "#{DEFAULT_TYPE}-site"
        options[:directory] ||= options[:name].gsub(/\s+/, "-").downcase
        options[:theme] ||= options[:directory]

        Generator.new(options).run
      end

      def self.parser(options)
        OptionParser.new do |opts|
          opts.banner = "Usage: typophic new [options]"

          opts.on("--name NAME", "Display name of the site") { |name| options[:name] = name }
          opts.on("--dir DIR", "Target directory (defaults to sanitized name)") { |dir| options[:directory] = dir }
          opts.on("--type TYPE", "Template type: blog, docs, ruby") { |type| options[:type] = type }
          opts.on("--author AUTHOR", "Author name for metadata") { |author| options[:author] = author }
          opts.on("--description TEXT", "Site description") { |desc| options[:description] = desc }
          opts.on("--theme NAME", "Theme directory name (defaults to sanitized site name)") { |theme| options[:theme] = theme }
          opts.on("-h", "--help", "Show this help message") do
            puts opts
            exit
          end
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
