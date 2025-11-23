# frozen_string_literal: true

require "option_parser"
require "file_utils"
require "../builder"

module Typophic
  module Commands
    module Build
      alias OptionValue = Bool | Int32 | String | Nil
      
      def self.run(argv : Array(String))
        options = Hash(Symbol, OptionValue).new
        options[:clean] = true
        options[:verbose] = true
        options[:deploy] = false
        options[:parallel] = true
        options[:thread_count] = nil

        parser(options).parse(argv)

        puts "==== Typophic: Build ====" if options[:verbose].as(Bool)
        clean_public_directory if options[:clean].as(Bool)

        builder_options = {
          "verbose" => options[:verbose].as(Bool).to_s,
          "parallel" => options[:parallel].as(Bool).to_s,
        }
        if options[:thread_count]?
          builder_options["thread_count"] = options[:thread_count].as(Int32).to_s
        end

        Typophic::Builder.new(builder_options).build

        create_deploy_artifacts if options[:deploy].as(Bool)
        create_htaccess

        puts "Site ready in public/." if options[:verbose].as(Bool)
      end

      def self.parser(options : Hash(Symbol, OptionValue))
        OptionParser.new do |opts|
          opts.banner = "Usage: typophic build [options]"

          opts.on("--no-clean", "Skip cleaning the public directory before building") do
            options[:clean] = false
          end

          opts.on("-q", "--quiet", "Reduce console output") do
            options[:verbose] = false
          end

          opts.on("--deploy", "Add deployment-specific artifacts (.nojekyll, 404.html)") do
            options[:deploy] = true
          end

          opts.on("--no-parallel", "Disable parallel processing (slower but more predictable)") do
            options[:parallel] = false
          end

          opts.on("--threads COUNT", "Number of threads for parallel processing (default: auto-detect)") do |count|
            options[:thread_count] = count.to_i
            options[:parallel] = true
          end

          opts.on("-h", "--help", "Show this help message") do
            puts opts
            exit
          end
        end
      end

      private def self.clean_public_directory
        return unless Dir.exists?("public")

        Dir.glob("public/*").each do |path|
          FileUtils.rm_rf(path)
        end
      end

      private def self.create_htaccess
        File.write("public/.htaccess", <<-HTACCESS)
          RewriteEngine On
          RewriteCond %{REQUEST_FILENAME} !-f
          RewriteCond %{REQUEST_FILENAME} !-d
          RewriteRule ^(.*)$ index.html [L]
        HTACCESS
      end

      private def self.create_deploy_artifacts
        File.write("public/.nojekyll", "")

        File.write("public/404.html", <<-HTML)
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="UTF-8">
            <title>Page Not Found</title>
            <style>
              body { font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; display: grid; place-items: center; min-height: 100vh; background: #0f172a; color: #e2e8f0; margin: 0; }
              .card { max-width: 24rem; text-align: center; padding: 2.5rem; background: rgba(15, 23, 42, 0.75); border-radius: 1rem; box-shadow: 0 20px 45px rgba(15, 23, 42, 0.45); backdrop-filter: blur(12px); }
              h1 { font-size: 3rem; margin-bottom: 0.75rem; color: #f97316; }
              p { margin-bottom: 1.5rem; line-height: 1.6; }
              a { color: #38bdf8; text-decoration: none; font-weight: 600; }
              a:hover { text-decoration: underline; }
              .countdown { margin-top: 0.5rem; font-size: 0.9rem; opacity: 0.85; }
            </style>
            <script>
              (function() {
                var seconds = 5;
                function tick() {
                  var el = document.getElementById('countdown');
                  if (!el) return;
                  el.textContent = seconds;
                  if (seconds <= 0) {
                    window.location.href = "/";
                  } else {
                    seconds -= 1;
                    setTimeout(tick, 1000);
                  }
                }
                document.addEventListener('DOMContentLoaded', tick);
              })();
            </script>
          </head>
          <body>
            <div class="card">
              <h1>404</h1>
              <p>The page you were looking for is off exploring Ruby metaprogramming.</p>
              <p><a href="/">Return home</a> or wait to be redirected.</p>
              <p class="countdown">Redirecting in <span id="countdown">5</span>…</p>
            </div>
          </body>
          </html>
        HTML
      end
    end
  end
end