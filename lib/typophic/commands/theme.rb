# frozen_string_literal: true

require "optparse"

require_relative "../theme_scaffolder"

module Typophic
  module Commands
    module Theme
      extend self

      def run(argv)
        subcommand = argv.shift

        case subcommand
        when "new"
          New.new(argv).run
        when nil, "help", "--help", "-h"
          puts help_text
        else
          warn "Unknown theme subcommand: #{subcommand}\n"
          puts help_text
          exit 1
        end
      end

      def help_text
        <<~HELP
          Usage: typophic theme <command> [options]

          Commands:
            new NAME   Scaffold a new theme under themes/NAME

          Run `typophic theme new --help` for command-specific options.
        HELP
      end

      class New
        def initialize(argv)
          @options = {
            path: Dir.pwd,
            site_name: "Typophic Site",
            description: "A Typophic theme",
            author: "Typophic User"
          }

          @parser = build_parser
          @parser.parse!(argv)

          @theme_name = argv.shift

          if @theme_name.nil? || @theme_name.strip.empty?
            warn "Theme name is required."
            puts @parser
            exit 1
          end
        end

        def run
          puts "Creating theme '#{@theme_name}' in #{target_path}"

          Typophic::ThemeScaffolder.generate(
            root_path: @options[:path],
            theme_name: @theme_name,
            site_name: @options[:site_name],
            description: @options[:description],
            author: @options[:author]
          )

          puts "Theme ready at #{File.join(target_path, @theme_name)}"
        end

        private

        def target_path
          File.join(@options[:path], "themes")
        end

        def build_parser
          OptionParser.new do |opts|
            opts.banner = "Usage: typophic theme new NAME [options]"

            opts.on("--path DIR", "Root directory (default: current working directory)") do |dir|
              @options[:path] = File.expand_path(dir)
            end

            opts.on("--site-name NAME", "Default site title used in the layout") do |name|
              @options[:site_name] = name
            end

            opts.on("--description TEXT", "Default meta description") do |text|
              @options[:description] = text
            end

            opts.on("--author NAME", "Footer attribution") do |author|
              @options[:author] = author
            end

            opts.on("-h", "--help", "Show this help message") do
              puts opts
              exit
            end
          end
        end
      end
    end
  end
end

