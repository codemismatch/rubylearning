# frozen_string_literal: true

require "optparse"
require "fileutils"
require "yaml"

require_relative "build"
require_relative "serve"

module Typophic
  module Commands
    module Deploy
      module_function

      def run(argv)
        config = load_config
        options = default_options(config)

        parser(options).parse!(argv)

        if options[:mode] == :local
          local_preview(options)
        else
          remote_publish(options)
        end
      end

      def parser(options)
        OptionParser.new do |opts|
          opts.banner = "Usage: typophic deploy [options]"

          opts.on("--local", "Run a local preview server instead of publishing") do
            options[:mode] = :local
          end

          opts.on("--port PORT", Integer, "Port for local preview (default: #{options[:port]})") do |port|
            options[:port] = port
          end

          opts.on("--watch", "Watch content/themes and rebuild automatically (local only)") do
            options[:watch] = true
          end

          opts.on("--remote NAME", "Git remote to push to (default: #{options[:remote]})") do |remote|
            options[:remote] = remote
          end

          opts.on("--branch NAME", "Git branch to push the public/ subtree to") do |branch|
            options[:branch] = branch
          end

          opts.on("--force", "Force push when publishing to GitHub Pages") do
            options[:force] = true
          end

          opts.on("--custom-domain DOMAIN", "Write a CNAME file before publishing") do |domain|
            options[:custom_domain] = domain
          end

          opts.on("-h", "--help", "Show this help message") do
            puts opts
            exit
          end
        end
      end

      def default_options(config)
        {
          mode: :github,
          remote: "origin",
          branch: config.dig("repository", "deploy_branch") || "gh-pages",
          force: false,
          custom_domain: nil,
          port: 3000,
          watch: false,
          watch_paths: %w[content themes helpers assets data config.yml],
          ignore_patterns: ["**/.DS_Store", "**/.git/**", "public/**/*"]
        }
      end

      def load_config
        YAML.load_file("config.yml")
      rescue Errno::ENOENT
        {}
      end

      def local_preview(options)
        puts "== Building site for local preview =="
        Typophic::Commands::Build.run([])

        watcher_thread = options[:watch] ? start_watcher(options) : nil

        begin
          Typophic::Commands::Serve.run(["--port", options[:port].to_s])
        ensure
          watcher_thread&.kill
        end
      end

      def remote_publish(options)
        puts "== Building site for deployment =="
        build_args = ["--deploy"]
        Typophic::Commands::Build.run(build_args)

        create_custom_domain(options[:custom_domain]) if options[:custom_domain]

        publish_to_git(options)
      end

      def create_custom_domain(domain)
        clean = domain.to_s.strip
        return if clean.empty?

        File.write(File.join("public", "CNAME"), clean)
        puts "Added CNAME for #{clean}"
      end

      def publish_to_git(options)
        remote = options[:remote]
        branch = options[:branch]
        force_flag = options[:force] ? "--force" : nil

        command = ["git", "subtree", "push", "--prefix", "public", remote, branch]
        command << force_flag if force_flag

        puts "== Publishing public/ to #{remote}/#{branch} =="
        unless system(*command.compact)
          warn "Git publish failed. Verify the remote name/branch or push manually."
        end
      end

      def start_watcher(options)
        watcher = FileWatcher.new(options[:watch_paths], options[:ignore_patterns])
        watcher.scan_initial
        puts "[watch] Watching #{options[:watch_paths].join(', ')}"

        Thread.new do
          loop do
            sleep 1
            changed = watcher.changed_files
            next if changed.empty?

            puts "\n[watch] Changes detected:\n  - #{changed.join('\n  - ')}"
            Typophic::Commands::Build.run(["--no-clean", "--quiet"])
          end
        end
      end

      class FileWatcher
        def initialize(paths, ignore_patterns)
          @paths = paths
          @ignore_patterns = ignore_patterns
          @snapshots = {}
        end

        def scan_initial
          visible_files.each { |file| @snapshots[file] = snapshot(file) }
        end

        def changed_files
          changes = []
          current = {}

          visible_files.each do |file|
            current[file] = snapshot(file)
            next if current[file] == @snapshots[file]

            changes << file
          end

          @snapshots = current
          changes
        end

        private

        def visible_files
          @paths.flat_map do |path|
            if File.directory?(path)
              Dir.glob(File.join(path, "**", "*"), File::FNM_DOTMATCH).reject do |file|
                File.directory?(file) || ignored?(file)
              end
            elsif File.exist?(path)
              ignored?(path) ? [] : [path]
            else
              []
            end
          end
        end

        def snapshot(file)
          stat = File.stat(file)
          [stat.mtime.to_f, stat.size]
        rescue Errno::ENOENT
          nil
        end

        def ignored?(file)
          flags = File::FNM_PATHNAME | File::FNM_DOTMATCH
          @ignore_patterns.any? { |pattern| File.fnmatch?(pattern, file, flags) }
        end
      end
    end
  end
end
