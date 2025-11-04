# frozen_string_literal: true

require "optparse"
require_relative "version"
require_relative "commands/build"
require_relative "commands/serve"
require_relative "commands/deploy"
require_relative "commands/new"
require_relative "commands/theme"
require_relative "commands/blog"
require_relative "commands/clean"
require_relative "commands/doctor"

module Typophic
  class CLI
    COMMANDS = {
      "build" => Commands::Build,
      "serve" => Commands::Serve,
      "s" => Commands::Serve,  # Alias for serve
      "deploy" => Commands::Deploy,
      "new" => Commands::New,
      "theme" => Commands::Theme,
      "blog" => Commands::Blog,
      "clean" => Commands::Clean,
      "doctor" => Commands::Doctor
    }.freeze

    def self.start(argv)
      new(argv).run
    end

    def initialize(argv)
      @argv = argv.dup
    end

    def run
      command = @argv.shift

      return print_help if command.nil? || command == "help"
      return print_version if version_flag?(command)

      if %w[-h --help].include?(command)
        print_help
        return
      end

      handler = COMMANDS[command]
      if handler.nil?
        warn "Unknown command: #{command}\n"
        print_help
        exit 1
      end

      handler.run(@argv)
    end

    private

    def version_flag?(flag)
      %w[-v --version].include?(flag)
    end

    def print_version
      puts "Typophic #{Typophic::VERSION}"
    end

    def print_help
      puts <<~HELP
        Typophic #{Typophic::VERSION}

        Usage: typophic [command] [options]

        Available commands:
          build       Build the static site (production-ready by default)
          serve, s    Serve the generated site with auto-rebuild and live reload
          deploy      Deploy the site (GitHub Pages by default; S3 and rsync supported)
          new         Generators for site/blog/post/page
          theme       Manage themes (new/use/install/list/remove)
          blog        Manage blog posts (new/publish/list/delete)
          clean       Remove generated artifacts (cleans public/)
          doctor      Validate project structure and configuration

        Quick examples:
          typophic new site mysite --theme rubylearning
          typophic new blog myblog --theme https://github.com/user/cool-theme
          typophic new post "Hello World" --tags intro --draft
          typophic new page "About" --permalink /about/
          typophic theme install https://github.com/user/cool-theme
          typophic blog list --drafts
          typophic deploy --remote origin --branch gh-pages
          typophic deploy --provider s3 --bucket my-bucket

        Run `typophic COMMAND --help` for detailed, command-specific options.
      HELP
    end
  end
end
