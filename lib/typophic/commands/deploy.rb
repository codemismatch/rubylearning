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

          opts.on("--provider NAME", "Provider: github (default), s3, rsync") do |name|
            options[:provider] = name.to_s.downcase.to_sym
          end

          # S3 options
          opts.on("--bucket NAME", "S3 bucket for provider s3") { |v| options[:bucket] = v }
          opts.on("--region NAME", "AWS region for provider s3") { |v| options[:region] = v }

          # rsync options
          opts.on("--dest USER@HOST:PATH", "rsync destination for provider rsync") { |v| options[:dest] = v }

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
          ignore_patterns: ["**/.DS_Store", "**/.git/**", "public/**/*"],
          provider: :github,
          bucket: nil,
          region: nil,
          dest: nil
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
        previous_override = nil

        # Determine domain for build-time URL override and CNAME:
        # 1. Explicit --custom-domain flag wins.
        # 2. Otherwise, derive host from config.yml url (if present).
        domain_for_cname = options[:custom_domain]
        if domain_for_cname.to_s.strip.empty?
          config = load_config
          raw_url = config.fetch("url", "").to_s.strip
          begin
            uri = raw_url.empty? ? nil : URI.parse(raw_url)
            host = uri&.host.to_s.strip
            domain_for_cname = host unless host.empty?
          rescue URI::InvalidURIError
            domain_for_cname = nil
          end
        end

        if domain_for_cname
          previous_override = ENV["TYPOPHIC_URL_OVERRIDE"]
          ENV["TYPOPHIC_URL_OVERRIDE"] = "https://#{domain_for_cname}"
        end

        begin
          Typophic::Commands::Build.run(build_args)
        ensure
          ENV["TYPOPHIC_URL_OVERRIDE"] = previous_override if domain_for_cname
        end

        create_custom_domain(domain_for_cname) if domain_for_cname

        case options[:provider]
        when :github
          publish_to_git(options)
        when :s3
          publish_to_s3(options)
        when :rsync
          publish_with_rsync(options)
        else
          warn "Unknown provider: #{options[:provider]} (supported: github, s3, rsync)"
        end
      end

      def create_custom_domain(domain)
        clean = domain.to_s.strip
        return if clean.empty?

        File.write(File.join("public", "CNAME"), clean)
        puts "Added CNAME for #{clean}"
      end

      def publish_to_s3(options)
        bucket = options[:bucket]
        if bucket.to_s.strip.empty?
          warn "--bucket is required for --provider s3"
          return
        end
        region = options[:region]
        args = ["aws", "s3", "sync", "public/", "s3://#{bucket}/", "--delete"]
        args += ["--region", region] if region
        puts "== Publishing public/ to s3://#{bucket}/ =="
        unless system(*args)
          warn "aws s3 sync failed. Ensure AWS CLI is installed and configured."
        end
      end

      def publish_with_rsync(options)
        dest = options[:dest]
        if dest.to_s.strip.empty?
          warn "--dest USER@HOST:PATH is required for --provider rsync"
          return
        end
        args = ["rsync", "-az", "--delete", "public/", dest]
        puts "== Publishing public/ to #{dest} via rsync =="
        unless system(*args)
          warn "rsync failed. Verify SSH access and destination path."
        end
      end

      def publish_to_git(options)
        remote = options[:remote]
        branch = options[:branch]
        force = options[:force]

        repo_root = Dir.pwd
        public_dir = File.join(repo_root, "public")

        unless Dir.exist?(public_dir)
          warn "public/ directory not found. Run `typophic build --deploy` first."
          return
        end

        worktree_dir = File.join(repo_root, ".typophic-gh-pages")

        if Dir.exist?(worktree_dir)
          FileUtils.rm_rf(worktree_dir)
        end

        puts "== Publishing public/ to #{remote}/#{branch} via worktree =="

        # Ensure we have the latest remote branch (if it exists)
        system("git", "fetch", remote, branch)

        worktree_added = system("git", "worktree", "add", "-B", branch, worktree_dir, "#{remote}/#{branch}")
        unless worktree_added
          # Branch might not exist yet; fall back to creating from current HEAD
          worktree_added = system("git", "worktree", "add", "-B", branch, worktree_dir, "HEAD")
        end

        unless worktree_added
          warn "Failed to create git worktree for #{branch}. Ensure git-worktree is available."
          return
        end

        begin
          # Clean existing files in the worktree (except .git)
          Dir.glob(File.join(worktree_dir, "*"), File::FNM_DOTMATCH).each do |path|
            base = File.basename(path)
            next if base == "." || base == ".." || base == ".git"
            FileUtils.rm_rf(path)
          end

          # Copy contents of public/ into the worktree
          Dir.glob(File.join(public_dir, "**", "*"), File::FNM_DOTMATCH).each do |source|
            base = File.basename(source)
            next if base == "." || base == ".."

            relative = source.sub(/^#{Regexp.escape(public_dir)}\/?/, "")
            next if relative == ".git" || relative.start_with?(".git/")
            target = relative.empty? ? worktree_dir : File.join(worktree_dir, relative)

            if File.directory?(source)
              FileUtils.mkdir_p(target)
            else
              FileUtils.mkdir_p(File.dirname(target))
              FileUtils.cp(source, target)
            end
          end

          Dir.chdir(worktree_dir) do
            system("git", "add", "-A")
            unless system("git", "commit", "-m", "Deploy site to #{branch}")
              puts "No changes to commit for #{branch}; working tree is up to date."
            end

            push_cmd = ["git", "push", remote, branch]
            push_cmd << "--force" if force

            unless system(*push_cmd)
              warn "Git publish failed. Verify the remote name/branch or push manually."
            end
          end
        ensure
          Dir.chdir(repo_root)
          system("git", "worktree", "remove", worktree_dir, "--force")
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
