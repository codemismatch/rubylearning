# frozen_string_literal: true

require "optparse"
require "fileutils"
require "listen"
require "webrick"
require_relative "../builder"

module Typophic
  module Commands
    module Serve
      DEFAULT_PORT = 3000
      CACHE_HEADERS = {
        "Cache-Control" => "no-store, no-cache, must-revalidate, max-age=0",
        "Pragma" => "no-cache",
        "Expires" => "0"
      }.freeze

      def self.run(argv)
        options = {
          port: DEFAULT_PORT,
          host: "localhost",
          build: false,
          watch: false
        }

        parser(options).parse!(argv)

        Typophic::Builder.new.build if options[:build]

        unless Dir.exist?("public")
          warn "Error: The 'public' directory does not exist. Please run `typophic build` first."
          exit 1
        end

        if options[:watch]
          start_watching_and_serving(options)
        else
          start_serving(options)
        end
      end

      def self.parser(options)
        OptionParser.new do |opts|
          opts.banner = "Usage: typophic serve [options]"

          opts.on("--port PORT", Integer, "Port to serve on (default: #{DEFAULT_PORT})") do |port|
            options[:port] = port
          end

          opts.on("--host HOST", "Host to bind to (default: localhost)") do |host|
            options[:host] = host
          end

          opts.on("--build", "Build the site before serving") do
            options[:build] = true
          end

          opts.on("--watch", "Watch for file changes and rebuild automatically") do
            options[:watch] = true
          end

          opts.on("-h", "--help", "Show this help message") do
            puts opts
            exit
          end
        end
      end

      def self.start_serving(options)
        server = build_server(options)

        trap("INT") do
          puts "\nServer stopped."
          server.shutdown
        end

        server.start
      end

      def self.start_watching_and_serving(options)
        server = build_server(options)

        # Start the HTTP server in a background thread
        server_thread = Thread.new do
          begin
            server.start
          rescue IOError
            # Socket closed during shutdown; suppress noisy stack trace
          end
        end

        # Set up file watcher to rebuild when content changes
        puts "\n=== Starting file watcher ==="
        puts "Watching content/, themes/, and root directory for changes..."
        
        listener = Listen.to(
          "content",
          "themes",
          ".",
          ignore: [/\.swp$/, /\.swx$/, /^\.[^\/]*\/tmp\//, /public\//],
          only: [/\.md$/, /\.html$/, /\.yml$/, /\.yaml$/, /\.rb$/]
        ) do |modified, added, removed|
          # Filter to only process the files we care about
          relevant_files = (modified + added + removed).select do |file|
            file.start_with?('content/', 'themes/', './config.yml') ||
            File.basename(file) == 'config.yml'
          end
          
          unless relevant_files.empty?
            puts "\nDetected changes:"
            puts "  Files: #{relevant_files.join(', ')}"
            
            begin
              puts "Rebuilding site..."
              Typophic::Builder.new.build
              puts "Site rebuilt successfully!"
            rescue => e
              warn "Build failed: #{e.message}"
            end
          end
        end

        listener.start

        # Wait for interrupt signal to stop
        trap("INT") do
          puts "\nStopping file watcher and server..."
          listener.stop
          server.shutdown
          server_thread.join
          exit
        end

        # Keep the main thread alive
        sleep
      end

      def self.htaccess_rules
        <<~HTACCESS
          RewriteEngine On
          RewriteCond %{REQUEST_FILENAME} !-f
          RewriteCond %{REQUEST_FILENAME} !-d
          RewriteRule ^(.*)$ index.html [L]
        HTACCESS
      end

      def self.build_server(options)
        File.write(File.join("public", ".htaccess"), htaccess_rules)

        puts "\n=== Starting local server ==="
        puts "Server running at http://#{options[:host]}:#{options[:port]}"
        puts "Press Ctrl+C to stop the server"

        document_root = File.expand_path("public")

        server = WEBrick::HTTPServer.new(
          Port: options[:port],
          BindAddress: options[:host],
          DocumentRoot: document_root,
          Logger: WEBrick::Log.new($stderr, WEBrick::Log::WARN),
          AccessLog: []
        )

        server.mount("/", NoCacheFileHandler, document_root)
        server
      end

      def self.apply_no_cache_headers(response)
        CACHE_HEADERS.each do |header, value|
          response[header] = value
        end
      end

      class NoCacheFileHandler < WEBrick::HTTPServlet::FileHandler
        def do_GET(request, response)
          super
        rescue WEBrick::HTTPStatus::NotFound
          raise unless spa_route?(request.path)

          request.path_info = "/index.html"
          super(request, response)
        ensure
          Typophic::Commands::Serve.apply_no_cache_headers(response) if response
        end

        alias do_HEAD do_GET

        private

        def spa_route?(path)
          return true if path.nil? || path == "/"
          !File.extname(path).match?(/\.[a-zA-Z0-9]+$/)
        end
      end
    end
  end
end
