# frozen_string_literal: true

require "optparse"
require_relative "version"

module Typophic
  class CLI
    COMMANDS = {
      "build" => -> { require_relative "commands/build"; Commands::Build },
      "serve" => -> { require_relative "commands/serve"; Commands::Serve },
      "s" => -> { require_relative "commands/serve"; Commands::Serve }, # Alias for serve
      "deploy" => -> { require_relative "commands/deploy"; Commands::Deploy },
      "new" => -> { require_relative "commands/new"; Commands::New },
      "theme" => -> { require_relative "commands/theme"; Commands::Theme },
      "blog" => -> { require_relative "commands/blog"; Commands::Blog },
      "clean" => -> { require_relative "commands/clean"; Commands::Clean },
      "doctor" => -> { require_relative "commands/doctor"; Commands::Doctor }
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

      handler_loader = COMMANDS[command]
      if handler_loader.nil?
        warn "Unknown command: #{command}\n"
        print_help
        exit 1
      end

      handler_loader.call.run(@argv)
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
