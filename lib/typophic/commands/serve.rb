# frozen_string_literal: true

require "optparse"
require "fileutils"
require "listen"
require "webrick"
require "stringio"
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
              
              # Update the last build time to trigger refresh
              Typophic::Commands::Serve.update_last_build_time(Time.now)
              
              # Notify live-reload clients if enabled
              if options[:livereload]
                notify_livereload_clients
              end
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
          end
        rescue WEBrick::HTTPStatus::NotFound
          raise unless spa_route?(request.path)

          request.path_info = "/index.html"
          super(request, response)
          
          # Add last-modified header for HTML files to support live-reload detection
          if response['Content-Type']&.include?('text/html')
            response['Last-Modified'] = Time.now.httpdate
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
          super(server, root)
          @options = options
        end

        def do_GET(request, response)
          # Get the original response
          super

          # Check if this is an HTML file that we should inject the script into
          if response['Content-Type']&.include?('text/html')
            original_body = response.body
            
            # Inject the live-reload script before the closing </body> tag
            # If no </body> tag is found, inject before </html>
            live_reload_script = <<~SCRIPT
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
                        console.log('Site rebuilt, reloading...');
                        window.location.reload();
                      }
                      lastBuildTime = parseInt(currentBuildTime);
                    })
                    .catch(function(error) {
                      // Ignore errors, especially if the endpoint doesn't exist
                    });
                  }
                  
                  // Check for changes every 1 second
                  setInterval(checkForChanges, 1000);
                })();
              </script>
            SCRIPT

            # Inject the script before </body> if it exists, otherwise before </html>
            if original_body.include?('</body>')
              modified_body = original_body.sub('</body>', live_reload_script + '</body>')
            elsif original_body.include?('</html>')
              modified_body = original_body.sub('</html>', live_reload_script + '</html>')
            else
              # If neither tag is found, append to body
              modified_body = original_body + live_reload_script
            end

            response.body = modified_body
            response['Content-Length'] = response.body.bytesize.to_s
          end
        rescue WEBrick::HTTPStatus::NotFound
          raise unless spa_route?(request.path)

          request.path_info = "/index.html"
          super(request, response)
          
          # Apply same HTML modification to SPA routes
          if response['Content-Type']&.include?('text/html')
            original_body = response.body
            
            # Inject the live-reload script before the closing </body> tag
            # If no </body> tag is found, inject before </html>
            live_reload_script = <<~SCRIPT
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
                        console.log('Site rebuilt, reloading...');
                        window.location.reload();
                      }
                      lastBuildTime = parseInt(currentBuildTime);
                    })
                    .catch(function(error) {
                      // Ignore errors, especially if the endpoint doesn't exist
                    });
                  }
                  
                  // Check for changes every 1 second
                  setInterval(checkForChanges, 1000);
                })();
              </script>
            SCRIPT

            # Inject the script before </body> if it exists, otherwise before </html>
            if original_body.include?('</body>')
              modified_body = original_body.sub('</body>', live_reload_script + '</body>')
            elsif original_body.include?('</html>')
              modified_body = original_body.sub('</html>', live_reload_script + '</html>')
            else
              # If neither tag is found, append to body
              modified_body = original_body + live_reload_script
            end

            response.body = modified_body
            response['Content-Length'] = response.body.bytesize.to_s
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
    end
  end
end
