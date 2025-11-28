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
require_relative "commands/verify"
require_relative "commands/format"
require_relative "commands/check_pipeline"
require_relative "commands/authors"
require_relative "commands/tutorial"
require_relative "commands/drafts"
require_relative "commands/course"

module Typophic
  class CLI
    COMMANDS = {
      "build" => Commands::Build,
      "serve" => Commands::Serve,
      "s" => Commands::Serve,
      "deploy" => Commands::Deploy,
      "new" => Commands::New,
      "theme" => Commands::Theme,
      "blog" => Commands::Blog,
      "authors" => Commands::Authors,
      "clean" => Commands::Clean,
      "doctor" => Commands::Doctor,
      "verify" => Commands::Verify,
      "format" => Commands::Format,
      "check_pipeline" => Commands::CheckPipeline,
      "tutorial" => Commands::Tutorial,
      "drafts" => Commands::Drafts,
      "course" => Commands::Course
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

      handler_class = COMMANDS[command]
      if handler_class.nil?
        warn "Unknown command: #{command}\n"
        print_help
        exit 1
      end

      handler_class.run(@argv)
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
          blog        Manage blog posts (new, publish, list, delete)
          tutorial    Manage tutorials (new, publish, list)
          drafts      List all drafts across content types
          clean       Remove generated artifacts (cleans public/)
          check-pipeline Verify the build pipeline is working
          theme       Manage themes (list, install, create)
          verify      Verify tutorial code samples and tests
          format      Format tutorial markdown files
          doctor      Diagnose common setup/config issues
          authors     Manage author data (refresh, list, add)

        Quick examples:
          typophic new site mysite --theme rubylearning
          typophic new blog myblog --theme https://github.com/user/cool-theme
          typophic new post "Hello World" --tags intro --draft
          typophic new page "About" --permalink /about/
          typophic theme install https://github.com/user/cool-theme
          typophic blog list --drafts
          typophic authors refresh
          typophic authors list
          typophic deploy --remote origin --branch gh-pages
          typophic deploy --provider s3 --bucket my-bucket

        Run `typophic COMMAND --help` for detailed, command-specific options.
      HELP
    end
  end
end
