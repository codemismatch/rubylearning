# frozen_string_literal: true

require "option_parser"
require "../builder"
require "http/server"
require "uri"
require "mime"
require "file_watcher"
require "log"
require "http"

module Typophic
  module Commands
    module Serve
      class_property last_build_time : Time = Time.unix_ms(0)
      
      alias OptionValue = Bool | Int32 | String | Nil

      def self.run(argv : Array(String))
        # Ensure we're in the project root, not the crystal subdirectory
        project_root = Dir.current
        if project_root.ends_with?("/crystal")
          project_root = File.dirname(project_root)
          Dir.cd(project_root)
        end
        
        options = Hash(Symbol, OptionValue).new
        options[:port] = 3000
        options[:host] = "localhost"
        options[:build] = false
        options[:build_site] = false
        options[:watch] = true
        options[:livereload] = true
        options[:parallel] = false  # Default to sequential for dev server (less overhead)
        options[:thread_count] = nil
        
        Log.setup_from_env

        parser(options).parse(argv)
        
        # Build the binary if --build is specified
        if options[:build].as(Bool)
          Log.info { "Building Crystal binary..." }
          crystal_dir = File.join(project_root, "crystal")
          binary_path = File.join(crystal_dir, "bin", "typophic")
          source_path = File.join(crystal_dir, "src", "bin", "typophic.cr")
          
          unless File.exists?(source_path)
            Log.error { "Source file not found: #{source_path}" }
            exit 1
          end
          
          # Build the binary
          build_cmd = "cd #{crystal_dir} && crystal build src/bin/typophic.cr -o bin/typophic"
          result = Process.run(build_cmd, shell: true, output: Process::Redirect::Inherit, error: Process::Redirect::Inherit)
          
          unless result.success?
            Log.error { "Failed to build binary. Exit code: #{result.exit_code}" }
            exit 1
          end
          
          Log.info { "Binary built successfully at #{binary_path}" }
        end
        
        # Build the site if --build-site is specified (or if --build is used, also build site)
        if options[:build_site].as(Bool) || options[:build].as(Bool)
          Log.info { "Building site before starting server..." }
          builder_options = {
            "verbose" => true.to_s,
            "parallel" => options[:parallel].as(Bool).to_s,
          }
          if options[:thread_count]?
            builder_options["thread_count"] = options[:thread_count].as(Int32).to_s
          end
          # For development server, default to sequential builds (less overhead)
          # unless explicitly enabled with --parallel
          builder_options["parallel"] = options[:parallel].as(Bool).to_s
          Typophic::Builder.new(builder_options).build
          self.last_build_time = Time.local
          Log.info { "Site build complete. Starting server..." }
        end

        unless Dir.exists?("public")
          Log.error { "The 'public' directory does not exist. Please run `typophic build` first." }
          exit 1
        end

        if options[:watch].as(Bool)
          start_watching_and_serving(options)
        else
          start_serving(options)
        end
      end

      def self.parser(options : Hash(Symbol, OptionValue))
        OptionParser.new do |opts|
          opts.banner = "Usage: typophic serve [options]"

          opts.on("--port PORT", "Port to serve on (default: 3000)") do |port|
            options[:port] = port.to_i
          end

          opts.on("--host HOST", "Host to bind to (default: localhost)") do |host|
            options[:host] = host
          end

          opts.on("--build", "Build the Crystal binary before serving") do
            options[:build] = true
          end

          opts.on("--build-site", "Build the site before serving") do
            options[:build_site] = true
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

          opts.on("--parallel", "Enable parallel processing during builds (uses auto-detected thread count, default: sequential)") do
            options[:parallel] = true
          end

          opts.on("--threads COUNT", "Number of threads for parallel processing (also enables parallel mode)") do |count|
            options[:thread_count] = count.to_i
            options[:parallel] = true
          end

          opts.on("-h", "--help", "Show this help message") do
            puts opts
            exit
          end
        end
      end

      def self.start_serving(options : Hash(Symbol, OptionValue))
        server = build_server(options)

        # Server will handle signals automatically
        host = options[:host].as(String)
        port = options[:port].as(Int32)
        
        begin
          Log.info { "Starting server at http://#{host}:#{port}" }
          server.listen(host, port)
        rescue ex : IO::Error
          Log.error(exception: ex) { "Failed to start server: #{ex.message}. Is the port already in use?" }
          exit 1
        end
      end
      
      def self.start_watching_and_serving(options : Hash(Symbol, OptionValue))
        server = build_server(options)
        
        spawn do
          begin
            Log.info { "Starting server at http://#{options[:host]}:#{options[:port]}" }
            server.listen(options[:host].as(String), options[:port].as(Int32))
          rescue ex : IO::Error
            Log.error(exception: ex) { "Server fiber failed to listen: #{ex.message}" }
          rescue ex
            Log.error(exception: ex) { "Server fiber error" }
          end
        end

        Log.info { "Watching for file changes..." }
        
        # Get the project root (parent of crystal directory if we're in crystal, or current dir)
        project_root = Dir.current
        if project_root.ends_with?("/crystal")
          project_root = File.dirname(project_root)
        end
        
        # Build absolute paths for directories to watch - only watch specific project directories
        # We watch each directory separately to avoid nested watching issues
        watch_dirs = [] of String
        
        %w[content themes layouts includes assets data].each do |dir|
          abs_path = File.join(project_root, dir)
          watch_dirs << abs_path if Dir.exists?(abs_path)
        end
        
        # Start file watcher in a fiber - watch each directory separately
        watcher_fiber = spawn do
          begin
            # Watch each directory separately to avoid nested directory conflicts
            # Each watch runs in its own fiber to prevent conflicts
            watch_dirs.each do |watch_dir|
              spawn do
                begin
                  FileWatcher.watch(watch_dir) do |event|
                    event_path = event.path
                    
                    # Double-check it's actually in our watched directory
                    next unless event_path.starts_with?(watch_dir)
                    
                    Log.info { "Detected change in #{event_path}, rebuilding..." }
                    begin
                      builder_options = {
                        "verbose" => false.to_s,
                        "parallel" => options[:parallel].as(Bool).to_s,  # Use same parallel setting as initial build
                      }
                      if options[:thread_count]?
                        builder_options["thread_count"] = options[:thread_count].as(Int32).to_s
                      end
                      Typophic::Builder.new(builder_options).build
                      self.last_build_time = Time.local
                      Log.info { "Rebuild complete." }
                    rescue ex
                      Log.error(exception: ex) { "Rebuild failed" }
                    end
                  end
                rescue ex
                  Log.error(exception: ex) { "Watcher error for #{watch_dir}: #{ex.message}" }
                end
              end
            end
            
            # Watch config.yml by using a simple file polling approach
            # This avoids watching the project root which would pick up crystal/lib
            config_path = File.join(project_root, "config.yml")
            if File.exists?(config_path)
              spawn do
                begin
                  last_mtime = File.info(config_path).modification_time
                  loop do
                    sleep 1.second
                    begin
                      current_mtime = File.info(config_path).modification_time
                      if current_mtime > last_mtime
                        last_mtime = current_mtime
                        Log.info { "Detected change in #{config_path}, rebuilding..." }
                        begin
                          builder_options = {
                            "verbose" => false.to_s,
                            "parallel" => options[:parallel].as(Bool).to_s,
                          }
                          if options[:thread_count]?
                            builder_options["thread_count"] = options[:thread_count].as(Int32).to_s
                          end
                          Typophic::Builder.new(builder_options).build
                          self.last_build_time = Time.local
                          Log.info { "Rebuild complete." }
                        rescue ex
                          Log.error(exception: ex) { "Rebuild failed" }
                        end
                      end
                    rescue File::NotFoundError
                      # Config file was deleted, skip
                    rescue ex
                      Log.error(exception: ex) { "Error checking config.yml: #{ex.message}" }
                    end
                  end
                rescue ex
                  Log.error(exception: ex) { "Config watcher error: #{ex.message}" }
                end
              end
            end
            
            # Keep the watcher fiber alive
            sleep
          rescue ex
            Log.error(exception: ex) { "File watcher error: #{ex.message}" }
          end
        end

        # Note: Signal handling in Crystal is different - the server will handle SIGINT automatically
        # For graceful shutdown, we rely on the server's built-in signal handling

        # Keep main fiber alive
        sleep
      end

      def self.build_server(options : Hash(Symbol, OptionValue))
        # Use absolute path from project root - ensure we're in the right directory
        project_root = Dir.current
        # If we're in crystal subdirectory, go up one level
        if project_root.ends_with?("/crystal")
          project_root = File.dirname(project_root)
        end
        document_root = File.expand_path("public", project_root)
        verbose = options[:verbose]?.try(&.as(Bool)) || false
        
        Log.info { "Serving from document_root: #{document_root}, exists: #{Dir.exists?(document_root)}, index.html exists: #{File.exists?(File.join(document_root, "index.html"))}" }
        
        handler_chain = StaticFileHandler.new(document_root, File.join(document_root, "404.html"), verbose)
        
        if options[:livereload]?.try(&.as(Bool)) || false
          handler_chain = LiveReloadHandler.new(handler_chain)
        end
        
        handler_chain = NoCacheHandler.new(handler_chain)

        # Create a handler that checks for the build_time route
        build_time_handler = BuildTimeHandler.new
        final_handler = RouteHandler.new(handler_chain, build_time_handler)
        
        HTTP::Server.new(final_handler)
      end

      class NoCacheHandler
        include HTTP::Handler

        def initialize(@next_handler : HTTP::Handler)
        end

        def call(context)
          context.response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate, max-age=0"
          context.response.headers["Pragma"] = "no-cache"
          context.response.headers["Expires"] = "0"
          @next_handler.call(context)
        end
      end

      class StaticFileHandler
        include HTTP::Handler

        def initialize(@document_root : String, @not_found_file : String, @verbose : Bool = false)
        end

        def call(context)
          # Normalize the request path - remove leading slash and handle root
          request_path = context.request.path
          
          # Handle root path explicitly first
          if request_path == "/" || request_path.empty?
            file_path = File.join(@document_root, "index.html")
          else
            # Remove leading slash for other paths
            request_path = request_path.lchop('/') if request_path.starts_with?('/')
            file_path = File.join(@document_root, request_path)
            if Dir.exists?(file_path)
              file_path = File.join(file_path, "index.html")
            end
          end

          # Ensure absolute path
          file_path = File.expand_path(file_path)
          exists = File.exists?(file_path)
          
          if exists
            begin
              content = File.read(file_path)
              context.response.headers["Content-Type"] = MIME.from_filename(file_path)
              context.response.print content
            rescue ex : IO::Error
              Log.error(exception: ex) { "Error reading file #{file_path}" }
              context.response.status = HTTP::Status::INTERNAL_SERVER_ERROR
              context.response.headers["Content-Type"] = "text/plain"
              context.response.print "500 Internal Server Error"
            end
          elsif File.exists?(@not_found_file) # SPA routing fallback (custom 404.html)
            begin
              context.response.status = HTTP::Status::NOT_FOUND
              context.response.headers["Content-Type"] = "text/html"
              context.response.print File.read(@not_found_file)
            rescue ex : IO::Error
              Log.error(exception: ex) { "Error reading 404 file #{@not_found_file}" }
              context.response.status = HTTP::Status::INTERNAL_SERVER_ERROR
              context.response.headers["Content-Type"] = "text/plain"
              context.response.print "500 Internal Server Error (404 file unreadable)"
            end
          else
            context.response.status = HTTP::Status::NOT_FOUND
            context.response.headers["Content-Type"] = "text/plain"
            context.response.print "404 Not Found"
          end
        end
      end

      class LiveReloadHandler
        include HTTP::Handler

        def initialize(@next_handler : HTTP::Handler)
        end

        def call(context : HTTP::Server::Context)
          @next_handler.call(context)
          # Note: Live reload injection not yet implemented
          # content_type = context.response.headers["Content-Type"]?
          # if content_type && content_type.starts_with?("text/html")
          #   inject_livereload(context.response)
          # end
        end

        private def inject_livereload(response : HTTP::Server::Response)
          # TODO: Implement live reload injection
          # This requires buffering the response body, which is complex in Crystal's HTTP::Server
          # For now, live reload is disabled - can be implemented later with a custom IO wrapper
        end

        private def append_livereload_script(html)
          script = LiveReloadScript.script
          if html.includes?("</body>")
            html.sub("</body>", "#{script}</body>")
          else
            html + script
          end
        end
      end

      module LiveReloadScript
        def self.script
          <<-SCRIPT
            <script data-typophic-livereload>
              (function() {
                var last_build = #{Serve.last_build_time.to_unix};
                setInterval(function() {
                  fetch('/__typophic__/build_time').then(function(res) {
                    return res.text();
                  }).then(function(time) {
                    if (time > last_build) {
                      window.location.reload();
                    }
                  });
                }, 1000);
              })();
            </script>
          SCRIPT
        end
      end

      class RouteHandler
        include HTTP::Handler
        
        def initialize(@next_handler : HTTP::Handler, @build_time_handler : BuildTimeHandler)
        end
        
        def call(context : HTTP::Server::Context)
          path = context.request.path
          if path == "/__typophic__/build_time"
            @build_time_handler.call(context)
          else
            # Always call next handler for all other paths
            @next_handler.call(context)
          end
        end
      end
      
      class BuildTimeHandler
        include HTTP::Handler
        
        def call(context : HTTP::Server::Context)
          context.response.status = HTTP::Status::OK
          context.response.content_type = "text/plain"
          context.response.print Serve.last_build_time.to_unix
        end
      end
    end
  end
end
