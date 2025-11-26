# frozen_string_literal: true

require "optparse"
require "fileutils"
require_relative "../theme_importer"

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
        when "install"
          Install.new(argv).run
        when "import"
          Import.new(argv).run
        when "list"
          List.run(argv)
        when "remove", "rm"
          Remove.new(argv).run
        when nil, "help", "--help", "-h"
          puts help_text
        else
          warn "Unknown theme subcommand: #{subcommand}\n"
          puts help_text
          exit 1
        end
      end

      # Helper method to slugify theme names (e.g., "Minimal Mistakes" -> "minimal-mistakes")
      def self.slugify_theme_name(name)
        name.to_s.strip.downcase.gsub(/[\s_]+/, "-").gsub(/[^a-z0-9\-]/, "")
      end

      def help_text
        <<~HELP
          Usage: typophic theme <command> [options]

          Commands:
            new NAME              Scaffold a new theme under themes/NAME
            use NAME [options]    Set default or section theme in config.yml
            install URL|OWNER/REPO[#ref] [--name NAME]
                                  Install a theme from GitHub into themes/NAME
            import SOURCE [--name NAME] [--staging DIR]
                                  Convert a local theme folder into Typophic layout
            list                  List installed themes
            remove NAME           Remove an installed theme directory

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
          # Normalize theme name to match directory name (e.g., "Minimal Mistakes" -> "minimal-mistakes")
          theme_dir = Theme.slugify_theme_name(@theme)
          
          unless Dir.exist?(File.join("themes", theme_dir))
            warn "Theme '#{@theme}' does not exist under themes/#{theme_dir}"
            warn "Install it first with: bin/typophic theme install \"#{@theme}\""
            exit 1
          end

          config = load_config
          config["theme"] = normalize_theme_config(config["theme"])

          if @options[:section]
            config["theme"]["sections"][@options[:section].to_s] = theme_dir
            puts "Applied theme '#{theme_dir}' to section '#{@options[:section]}' (from '#{@theme}')"
          end

          if @options[:default] || !@options[:section]
            config["theme"]["default"] = theme_dir
            puts "Set default theme to '#{theme_dir}' (from '#{@theme}')"
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

      class Install
        def initialize(argv)
          @options = { name: nil }
          @parser = OptionParser.new do |opts|
            opts.banner = "Usage: typophic theme install URL|OWNER/REPO[#ref] [--name NAME]"
            opts.on("--name NAME", "Target theme directory name") { |v| @options[:name] = v }
            opts.on("-h", "--help", "Show help") { puts opts; exit }
          end
          @parser.parse!(argv)
          @source = argv.shift
          if @source.to_s.strip.empty?
            warn "Source required (GitHub URL or OWNER/REPO[#ref])"
            puts @parser
            exit 1
          end
        end

        def run
          url, name, ref = resolve_source(@source)
          name = @options[:name] || name
          target = File.join("themes", name)
          
          if Dir.exist?(target)
            puts "Theme directory already exists: #{target}"
            exit 1
          end
          
          puts "Installing #{name} from #{url}..."
          unless system("git clone --depth 1 #{url} #{target}")
            abort("git clone failed")
          end
          
          if ref && !ref.strip.empty?
            system("git -C #{target} fetch --all")
            unless system("git -C #{target} checkout #{ref}")
              puts "Failed to checkout ref '#{ref}', staying on default branch"
            end
          end
          
          puts "Installed theme to #{target}"
        end

        private

        def resolve_source(src)
          # 1. Check if it's a direct URL or shorthand
          if src =~ %r{^https?://} || src =~ %r{^git@}
            return [src, infer_name_from_url(src), nil]
          end
          
          if src.include?("/") && !src.include?(" ") # Simple heuristic for owner/repo
            parts = src.split("/", 2)
            owner, repo_ref = parts[0], parts[1]
            repo_parts = repo_ref.split("#", 2)
            repo = repo_parts[0]
            ref = repo_parts[1]
            return ["https://github.com/#{owner}/#{repo}.git", repo, ref]
          end
          abort("Could not resolve theme source: '#{src}'. Provide a URL or OWNER/REPO[#ref].")
        end

        def infer_name_from_url(url)
          File.basename(url.to_s.sub(/\.git\z/, ""))
        end
      end

      class Import
        def initialize(argv)
          @options = { name: nil, staging: File.join("tmp", "theme-import") }
          @parser = OptionParser.new do |opts|
            opts.banner = "Usage: typophic theme import SOURCE [options]"
            opts.on("--name NAME", "Target theme directory name") { |v| @options[:name] = v }
            opts.on("--staging DIR", "Temporary staging directory (default: tmp/theme-import)") { |dir| @options[:staging] = dir }
            opts.on("-h", "--help", "Show help") { puts opts; exit }
          end
          @parser.parse!(argv)
          @source = argv.shift
          if @source.to_s.strip.empty?
            warn "Source required (path to a theme directory)"
            puts @parser
            exit 1
          end
        end

        def run
          importer = Typophic::ThemeImporter.new(
            target_root: "themes",
            staging_root: @options[:staging]
          )

          result = importer.import(@source, name: @options[:name])
          puts "Imported theme '#{result.name}' to #{result.target_path}"
          result.summary_lines.each { |line| puts "  - #{line}" }

          return if result.warnings.empty?

          puts "Warnings:"
          result.warnings.each { |warning| puts "  - #{warning}" }
        rescue StandardError => e
          warn "Import failed: #{e.message}"
          exit 1
        end
      end

      module List
        extend self

        def run(argv = [])
          parser = OptionParser.new do |opts|
            opts.banner = "Usage: typophic theme list"
            opts.on("-h", "--help", "Show help") { puts opts; exit }
          end
          parser.parse!(argv)

          list_installed_themes
        end

        def list_installed_themes
          themes_dir = "themes"
          unless Dir.exist?(themes_dir)
            puts "No themes directory found."
            return
          end

          themes = Dir.children(themes_dir).select { |child| File.directory?(File.join(themes_dir, child)) }
          
          if themes.empty?
            puts "No themes installed."
          else
            puts "Installed themes:"
            themes.each do |theme|
              puts "  - #{theme}"
            end
          end
        end

      end

      class Remove
        def initialize(argv)
          @name = nil
          parser = OptionParser.new do |opts|
            opts.banner = "Usage: typophic theme remove NAME"
            opts.on("-h", "--help", "Show help") { puts opts; exit }
          end
          parser.parse!(argv)
          
          @name = argv.shift
          if @name.nil? || @name.strip.empty?
            puts "Theme NAME is required"
            puts parser
            exit 1
          end
        end

        def run
          path = File.join("themes", @name)
          if Dir.exist?(path)
            FileUtils.rm_rf(path)
            puts "Removed theme #{path}"
          else
            puts "Theme not found: #{path}"
            exit 1
          end
        end
      end

    end
  end
end
