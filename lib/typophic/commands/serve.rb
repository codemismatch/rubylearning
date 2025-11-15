# frozen_string_literal: true

require "optparse"
require "fileutils"
begin
  require "listen"
rescue LoadError
  warn "Error: The `listen` gem is required for `typophic serve`."
  warn "Install it with `gem install listen -v '~> 3.0'`"
  warn "or run `bundle install` in this project."
  exit 1
end
require "webrick"
require "stringio"
require "tempfile"
require_relative "../builder"

module Typophic
  module Commands
    module Serve
      DEFAULT_PORT = 3000
      DEFAULT_LIVERELOAD_PORT = 35729
      @@last_build_time = Time.now
      @@server_instance = nil
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
          watch: true,  # Enable watch by default for development
          livereload: true  # Enable livereload by default for development
        }

        parser(options).parse!(argv)

        if options[:build]
          Typophic::Builder.new.build
          update_last_build_time(Time.now)
        end

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

          opts.on("--livereload", "Enable live reload on file changes (enabled by default)") do
            options[:livereload] = true
          end

          opts.on("--no-watch", "Disable file watching (watching is enabled by default)") do
            options[:watch] = false
          end

          opts.on("--no-livereload", "Disable live reload (live reload is enabled by default)") do
            options[:livereload] = false
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
        # Store server instance to access it from the file watcher
        server = build_server(options)
        @@server_instance = server if options[:livereload]

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
        puts "Watching project directories for changes..."

        project_root = Dir.pwd
        watched_dirs = %w[content themes layouts includes helpers assets data].select { |dir| Dir.exist?(dir) }
        watched_dirs << "."

        listener = Listen.to(
          *watched_dirs,
          ignore: [/\.swp$/, /\.swx$/, /^\.[^\/]*\/tmp\//, /public\//],
          only: [/\.(md|html|yml|yaml|rb|erb|css|scss|js)\z/]
        ) do |modified, added, removed|
          relative_paths = (modified + added + removed).map do |path|
            path.start_with?("#{project_root}/") ? path.sub("#{project_root}/", "") : path
          end

          relevant_files = relative_paths.select do |relative|
            relative.start_with?('content/', 'themes/', 'layouts/', 'includes/', 'helpers/', 'assets/', 'data/') ||
              relative == 'config.yml'
          end

          next if relevant_files.empty?

          puts "\nDetected changes:"
          puts "  Files: #{relevant_files.join(', ')}"

          begin
            puts "Rebuilding site..."
            Typophic::Builder.new.build
            puts "Site rebuilt successfully!"

            # Update the last build time to trigger refresh
            Typophic::Commands::Serve.update_last_build_time(Time.now)

            # Notify live-reload clients if enabled
            notify_livereload_clients if options[:livereload]
          rescue => e
            warn "Build failed: #{e.message}"
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
        if options[:livereload]
          puts "LiveReload enabled"
        end
        puts "Press Ctrl+C to stop the server"

        document_root = File.expand_path("public")

        server = WEBrick::HTTPServer.new(
          Port: options[:port],
          BindAddress: options[:host],
          DocumentRoot: document_root,
          Logger: WEBrick::Log.new($stderr, WEBrick::Log::WARN),
          AccessLog: []
        )

        if options[:livereload]
          server.mount("/", LiveReloadFileHandler, document_root, options)
          server.mount("/__typophic__/build_time", BuildTimeServlet)
        else
          server.mount("/", NoCacheFileHandler, document_root)
        end

        server
      end

      def self.apply_no_cache_headers(response)
        CACHE_HEADERS.each do |header, value|
          response[header] = value
        end
        response['Content-Type'] = ensure_utf8_content_type(response['Content-Type']) if response
      end

      def self.ensure_utf8_content_type(content_type)
        return 'text/html; charset=utf-8' if content_type.nil?

        return content_type if content_type.downcase.include?('charset')

        if content_type.downcase.start_with?('text/') || content_type.downcase.include?('html')
          "#{content_type}; charset=utf-8"
        else
          content_type
        end
      end

      def self.notify_livereload_clients
        # This method will be called when files change to trigger
        # a browser refresh through the live-reload script
        # In a real implementation we'd send a WebSocket message
        # For now, we'll just log that a reload should happen
        puts "LiveReload: Notifying clients to reload..."
      end

      def self.get_last_build_time
        @@last_build_time
      end

      def self.update_last_build_time(time)
        @@last_build_time = time
      end

      class NoCacheFileHandler < WEBrick::HTTPServlet::FileHandler
        def do_GET(request, response)
          super
          
          # Add last-modified header for HTML files to support live-reload detection
          if response['Content-Type']&.include?('text/html')
            response['Last-Modified'] = Time.now.httpdate
            response.body = response.body.force_encoding(Encoding::UTF_8)
            response['Content-Type'] = 'text/html; charset=utf-8'
          end
        rescue WEBrick::HTTPStatus::NotFound
          raise unless spa_route?(request.path)

          request.path_info = "/index.html"
          super(request, response)
          
          # Add last-modified header for HTML files to support live-reload detection
          if response['Content-Type']&.include?('text/html')
            response['Last-Modified'] = Time.now.httpdate
            response.body = response.body.force_encoding(Encoding::UTF_8)
            response['Content-Type'] = 'text/html; charset=utf-8'
          end
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

      class BuildTimeServlet < WEBrick::HTTPServlet::AbstractServlet
        def do_GET(request, response)
          response.status = 200
          response['Content-Type'] = 'text/plain'
          response.body = Typophic::Commands::Serve.get_last_build_time.to_i.to_s
        end
      end

      class LiveReloadFileHandler < WEBrick::HTTPServlet::FileHandler
        def initialize(server, root, options = {})
          # Initialize with proper options structure for WEBrick
          full_options = {
            :FancyIndexing => false,
            :NondisclosureName => [".ht*", "~*"]
          }.merge(options)
          
          super(server, root, full_options)
          @typophic_options = options
        end

        def do_GET(request, response)
          super
          inject_livereload(response)
        rescue WEBrick::HTTPStatus::NotFound
          raise unless spa_route?(request.path)

          request.path_info = "/index.html"
          super(request, response)
          inject_livereload(response)
        ensure
          Typophic::Commands::Serve.apply_no_cache_headers(response) if response
        end

        alias do_HEAD do_GET

        private

        def spa_route?(path)
          return true if path.nil? || path == "/"
          !File.extname(path).match?(/\.[a-zA-Z0-9]+$/)
        end

        def inject_livereload(response)
          return unless response['Content-Type']&.include?('text/html')

          html = extract_body(response)
          return if html.nil? || html.empty? || html.include?('data-typophic-livereload')

          modified = append_livereload_script(html)
          response.body = modified.force_encoding(Encoding::UTF_8)
          response['Content-Length'] = modified.bytesize.to_s
          response['Last-Modified'] = Time.now.httpdate
          response['Content-Type'] = 'text/html; charset=utf-8'
        end

        def extract_body(response)
          body = response.body

          case body
          when String
            body.dup
          when IO, StringIO
            body.rewind if body.respond_to?(:rewind)
            content = body.read
            body.close if body.respond_to?(:close)
            content
          when Tempfile
            body.rewind
            content = body.read
            body.close
            content
          else
            body.to_s
          end
        end

        def append_livereload_script(html)
          script = live_reload_script
          injection = "<!-- data-typophic-livereload -->\n#{script}"

          html = html.dup
          source_encoding = html.encoding
          source_encoding = Encoding::UTF_8 if source_encoding == Encoding::ASCII_8BIT

          html = html.encode(source_encoding, invalid: :replace, undef: :replace)
          injection = injection.encode(source_encoding, invalid: :replace, undef: :replace)

          if html.include?("</body>")
            html.sub("</body>", "#{injection}\n</body>")
          elsif html.include?("</html>")
            html.sub("</html>", "#{injection}\n</html>")
          else
            html + "\n" + injection
          end
        end

        def live_reload_script
          <<~SCRIPT
            <script>
              // LiveReload script - checks build timestamp to detect changes
              (function() {
                var lastBuildTime = null;

                function checkForChanges() {
                  fetch('/__typophic__/build_time', {
                    cache: 'no-cache'
                  })
                  .then(function(response) {
                    return response.text();
                  })
                  .then(function(currentBuildTime) {
                    if (lastBuildTime && currentBuildTime && currentBuildTime !== lastBuildTime.toString()) {
                      console.log('Typophic: site rebuilt, reloading…');
                      window.location.reload();
                    }
                    lastBuildTime = parseInt(currentBuildTime);
                  })
                  .catch(function(error) {
                    // Silently ignore errors; the endpoint might be unavailable during restarts.
                  });
                }

                checkForChanges();
                setInterval(checkForChanges, 1000);
              })();
            </script>
          SCRIPT
        end
      end
    end
  end
end
