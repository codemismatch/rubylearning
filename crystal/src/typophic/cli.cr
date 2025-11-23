require "./version"
require "./commands/*"

module Typophic
  class CLI
    COMMANDS = {
      "build" => Commands::Build,
      "serve" => Commands::Serve,
      "s"      => Commands::Serve,
      "deploy" => Commands::Deploy,
      "new"    => Commands::New,
      "theme"  => Commands::Theme,
      "blog"   => Commands::Blog,
      "clean"  => Commands::Clean,
      "doctor" => Commands::Doctor,
    }

    def self.start(argv : Array(String))
      new(argv).run
    end

    def initialize(@argv : Array(String))
    end

    def run
      command = @argv.shift?

      return print_help if command.nil? || command == "help"
      return print_version if version_flag?(command)

      if ["-h", "--help"].includes?(command)
        print_help
        return
      end

      handler_class = COMMANDS[command]?
      if handler_class.nil?
        STDERR.puts "Unknown command: #{command}\n"
        print_help
        exit 1
      end

      handler_class.run(@argv)
    end

    private def version_flag?(flag : String?) : Bool
      ["-v", "--version"].includes?(flag)
    end

    private def print_version
      puts "Typophic #{Typophic::VERSION}"
    end

    private def print_help
      puts <<-HELP
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
