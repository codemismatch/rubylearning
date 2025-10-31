# frozen_string_literal: true

require "optparse"
require_relative "version"
require_relative "commands/build"
require_relative "commands/serve"
require_relative "commands/deploy"
require_relative "commands/new"
require_relative "commands/theme"
require_relative "commands/blog"

module Typophic
  class CLI
    COMMANDS = {
      "build" => Commands::Build,
      "serve" => Commands::Serve,
      "s" => Commands::Serve,  # Alias for serve
      "deploy" => Commands::Deploy,
      "new" => Commands::New,
      "theme" => Commands::Theme,
      "blog" => Commands::Blog
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
          build     Build the static site (production-ready by default)
          serve, s  Serve the generated site with auto-rebuild and live reload
          deploy    Deploy the site or run pre-deploy steps
          new       Scaffold new content or starter sites
          theme     Manage themes (e.g. `typophic theme new <name>`)
          blog      Create or publish blog posts (drafts & articles)

        Run `typophic COMMAND --help` for command-specific options.
      HELP
    end
  end
end
