# frozen_string_literal: true

require "optparse"
require "fileutils"
require_relative "../builder"

module Typophic
  module Commands
    module Build
      def self.run(argv)
        options = {
          clean: true,
          verbose: true,
          deploy: false
        }

        parser(options).parse!(argv)

        puts "==== Typophic: Build ====" if options[:verbose]
        clean_public_directory if options[:clean]

        Typophic::Builder.new.build

        create_deploy_artifacts if options[:deploy]
        create_htaccess

        puts "Site ready in public/." if options[:verbose]
      end

      def self.parser(options)
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

          opts.on("-h", "--help", "Show this help message") do
            puts opts
            exit
          end
        end
      end

      def self.clean_public_directory
        return unless Dir.exist?("public")

        FileUtils.rm_rf(Dir.glob("public/*"))
      end

      def self.create_htaccess
        File.write("public/.htaccess", <<~HTACCESS)
          RewriteEngine On
          RewriteCond %{REQUEST_FILENAME} !-f
          RewriteCond %{REQUEST_FILENAME} !-d
          RewriteRule ^(.*)$ index.html [L]
        HTACCESS
      end

      def self.create_deploy_artifacts
        File.write("public/.nojekyll", "")

        File.write("public/404.html", <<~HTML)
          <!DOCTYPE html>
          <html lang="en">
          <head>
            <meta charset="UTF-8">
            <meta http-equiv="refresh" content="5;url=/">
            <title>Page Not Found</title>
            <style>
              body { font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif; display: grid; place-items: center; min-height: 100vh; background: #0f172a; color: #e2e8f0; margin: 0; }
              .card { max-width: 24rem; text-align: center; padding: 2.5rem; background: rgba(15, 23, 42, 0.75); border-radius: 1rem; box-shadow: 0 20px 45px rgba(15, 23, 42, 0.45); backdrop-filter: blur(12px); }
              h1 { font-size: 3rem; margin-bottom: 0.75rem; color: #f97316; }
              p { margin-bottom: 1.5rem; line-height: 1.6; }
              a { color: #38bdf8; text-decoration: none; font-weight: 600; }
              a:hover { text-decoration: underline; }
            </style>
          </head>
          <body>
            <div class="card">
              <h1>404</h1>
              <p>The page you were looking for is off exploring Ruby metaprogramming.</p>
              <p><a href="/">Return home</a> or wait to be redirected.</p>
            </div>
          </body>
          </html>
        HTML
      end

      private_class_method :clean_public_directory, :create_htaccess, :create_deploy_artifacts
    end
  end
end

