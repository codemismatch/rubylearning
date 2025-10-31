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
        when "use", "switch"
          Use.new(argv).run
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
            new NAME            Scaffold a new theme under themes/NAME
            use NAME [options]  Set default or section theme in config.yml

          Options for `use`:
            --default           Make NAME the default site theme
            --section SECTION   Apply NAME to a section (e.g., posts)

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

      class Use
        def initialize(argv)
          @options = { default: false, section: nil }
          @parser = OptionParser.new do |opts|
            opts.banner = "Usage: typophic theme use NAME [--default] [--section SECTION]"
            opts.on("--default", "Set as default theme") { @options[:default] = true }
            opts.on("--section SECTION", "Section to target (e.g., posts)") { |s| @options[:section] = s }
            opts.on("-h", "--help", "Show help") { puts opts; exit }
          end
          @parser.parse!(argv)
          @theme = argv.shift
          if @theme.to_s.strip.empty?
            warn "Theme NAME is required"
            puts @parser
            exit 1
          end
        end

        def run
          unless Dir.exist?(File.join("themes", @theme))
            warn "Theme '#{@theme}' does not exist under themes/#{@theme}"
            exit 1
          end

          config = load_config
          config["theme"] = normalize_theme_config(config["theme"])

          if @options[:section]
            config["theme"]["sections"][@options[:section].to_s] = @theme
            puts "Applied theme '#{@theme}' to section '#{@options[:section]}'"
          end

          if @options[:default] || !@options[:section]
            config["theme"]["default"] = @theme
            puts "Set default theme to '#{@theme}'"
          end

          File.write("config.yml", config.to_yaml)
          puts "Updated config.yml"
        end

        private

        def load_config
          YAML.load_file("config.yml")
        rescue Errno::ENOENT
          {}
        end

        def normalize_theme_config(value)
          case value
          when String
            { "default" => value, "sections" => {} }
          when Hash
            {
              "default" => (value["default"] || value[:default]).to_s,
              "sections" => (value["sections"] || value[:sections] || {}).transform_keys(&:to_s).transform_values(&:to_s)
            }
          else
            { "default" => "rubylearning", "sections" => {} }
          end
        end
      end
    end
  end
end
