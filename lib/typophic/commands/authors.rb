# frozen_string_literal: true

require 'yaml'
require 'net/http'
require 'json'
require 'uri'
require 'date'
require 'optparse'

module Typophic
  module Commands
    module Authors
      AUTHORS_FILE = "data/authors.yml"
      GITHUB_API_BASE = "https://api.github.com"

      def self.run(argv)
        subcommand = argv.shift

        case subcommand
        when "refresh"
          refresh(argv)
        when "list"
          list(argv)
        when "add"
          add(argv)
        when "-h", "--help", "help", nil
          print_help
        else
          warn "Unknown subcommand: #{subcommand}"
          print_help
          exit 1
        end
      end

      def self.print_help
        puts <<~HELP
          Usage: typophic authors <subcommand> [options]

          Subcommands:
            refresh    Rebuild authors.yml from Git history and GitHub API
            list       List all authors from authors.yml
            add        Add a new author by GitHub username

          Examples:
            typophic authors refresh              # Scan Git and update authors.yml
            typophic authors refresh --dry-run    # Preview changes without writing
            typophic authors list                 # Show all registered authors
            typophic authors add metacritical     # Add author by GitHub username

          Options for 'refresh':
            --dry-run    Preview changes without modifying authors.yml

          Environment:
            GITHUB_TOKEN    Personal access token for higher API rate limits (5000/hr vs 60/hr)
        HELP
      end

      def self.refresh(argv)
        dry_run = argv.include?("--dry-run")
        
        puts "=" * 60
        puts "  Typophic Authors Refresh"
        puts "=" * 60
        puts ""
        
        refresher = AuthorsRefresher.new(dry_run: dry_run)
        refresher.run
        
        puts ""
        puts "=" * 60
        puts "  #{dry_run ? 'DRY RUN COMPLETE' : 'DONE'}"
        puts "=" * 60
      end

      def self.list(argv)
        unless File.exist?(AUTHORS_FILE)
          warn "No authors.yml found. Run 'typophic authors refresh' first."
          exit 1
        end

        authors = YAML.safe_load(File.read(AUTHORS_FILE), permitted_classes: [Date], aliases: true)
        
        puts "Authors (#{authors.size} total):"
        puts ""
        
        authors.each do |id, data|
          puts "  #{id}"
          puts "    Name: #{data['name']}"
          puts "    GitHub: @#{data['github']}" if data['github']
          puts "    Emails: #{data['emails'].join(', ')}" if data['emails']
          puts ""
        end
      end

      def self.add(argv)
        username = argv.shift
        
        if username.nil? || username.empty?
          warn "GitHub username required"
          puts "Usage: typophic authors add USERNAME"
          exit 1
        end

        puts "Fetching GitHub data for @#{username}..."
        github_data = fetch_github_data(username)
        
        unless github_data
          warn "Could not fetch data for @#{username}. Check username and try again."
          exit 1
        end

        author_id = username.downcase.gsub(/[^a-z0-9]/, "")
        
        authors = File.exist?(AUTHORS_FILE) ? YAML.safe_load(File.read(AUTHORS_FILE), permitted_classes: [Date], aliases: true) : {}
        
        if authors[author_id]
          warn "Author '#{author_id}' already exists in authors.yml"
          exit 1
        end

        authors[author_id] = {
          "github" => username,
          "emails" => [],
          "name" => github_data[:name] || username,
          "avatar" => github_data[:avatar],
          "bio" => github_data[:bio] || "Contributor",
          "cached_at" => Date.today.to_s
        }

        write_authors_file(authors)
        
        puts "✅ Added author: #{author_id}"
        puts "   Name: #{authors[author_id]['name']}"
        puts "   GitHub: @#{username}"
      end

      def self.fetch_github_data(username)
        uri = URI("#{GITHUB_API_BASE}/users/#{username}")
        
        headers = {}
        if ENV['GITHUB_TOKEN']
          headers['Authorization'] = "Bearer #{ENV['GITHUB_TOKEN']}"
        end
        
        response = Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
          request = Net::HTTP::Get.new(uri)
          headers.each { |k, v| request[k] = v }
          http.request(request)
        end
        
        if response.code == "200"
          data = JSON.parse(response.body)
          {
            name: data["name"],
            avatar: data["avatar_url"],
            bio: data["bio"]
          }
        else
          nil
        end
      rescue => e
        warn "GitHub API error: #{e.message}"
        nil
      end

      def self.write_authors_file(authors_data)
        content = "# Typophic Author Registry\n"
        content += "#\n"
        content += "# Auto-generated/updated by typophic authors refresh\n"
        content += "# Last updated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}\n"
        content += "\n"
        content += YAML.dump(authors_data)
        
        File.write(AUTHORS_FILE, content)
      end

      class AuthorsRefresher
        def initialize(dry_run: false)
          @dry_run = dry_run
          @existing_authors = load_existing_authors
          @git_commits = scan_git_history
        end
        
        def run
          puts "🔍 Scanning Git history for authors..."
          puts "   Found #{@git_commits.size} unique commit emails\n\n"
          
          authors_data = {}
          
          @git_commits.each do |email, name|
            author_id = email_to_author_id(email)
            
            puts "📧 Processing: #{name} <#{email}>"
            
            if @existing_authors[author_id]
              puts "   ✓ Already exists as '#{author_id}'"
              authors_data[author_id] = update_existing_author(author_id, email)
            else
              puts "   + New author, creating entry..."
              authors_data[author_id] = create_new_author(author_id, email, name)
            end
            
            puts ""
          end
          
          if @dry_run
            puts "\n🔍 DRY RUN - Would write to #{AUTHORS_FILE}:"
            puts YAML.dump(authors_data)
          else
            Authors.write_authors_file(authors_data)
            puts "\n✅ Successfully updated #{AUTHORS_FILE}"
            puts "   Total authors: #{authors_data.size}"
          end
        end
        
        private
        
        def load_existing_authors
          return {} unless File.exist?(AUTHORS_FILE)
          
          YAML.safe_load(File.read(AUTHORS_FILE), permitted_classes: [Date], aliases: true) || {}
        rescue => e
          warn "⚠️  Could not load existing authors.yml: #{e.message}"
          {}
        end
        
        def scan_git_history
          output = `git log --all --format="%ae|%an" 2>/dev/null`
          
          commits = {}
          output.lines.each do |line|
            email, name = line.strip.split("|", 2)
            next if email.nil? || email.empty?
            
            email = email.downcase.strip
            commits[email] ||= name
          end
          
          commits
        end
        
        def email_to_author_id(email)
          username = email.split("@").first
          username.gsub(/[^a-z0-9]/, "").downcase
        end
        
        def update_existing_author(author_id, email)
          author = @existing_authors[author_id].dup
          
          emails = Array(author["emails"] || [])
          emails << email unless emails.include?(email)
          author["emails"] = emails.uniq.sort
          
          if author["github"]
            github_data = Authors.fetch_github_data(author["github"])
            if github_data
              author["name"] = github_data[:name] if github_data[:name]
              author["avatar"] = github_data[:avatar]
              author["bio"] = github_data[:bio]
              author["cached_at"] = Date.today.to_s
              puts "   ↻ Refreshed from GitHub: @#{author['github']}"
            end
          end
          
          author
        end
        
        def create_new_author(author_id, email, name)
          github_username = guess_github_username(email, name)
          
          author = {
            "github" => github_username || author_id,
            "emails" => [email],
            "name" => name,
            "avatar" => nil,
            "bio" => "Contributor",
            "cached_at" => Date.today.to_s
          }
          
          if github_username
            github_data = Authors.fetch_github_data(github_username)
            if github_data
              author["name"] = github_data[:name] || name
              author["avatar"] = github_data[:avatar]
              author["bio"] = github_data[:bio] || "Contributor"
              puts "   ✓ Fetched from GitHub: @#{github_username}"
            else
              puts "   ⚠️  Could not fetch from GitHub, using defaults"
            end
          else
            puts "   ⚠️  No GitHub username found, using email-based ID"
          end
          
          author["avatar"] ||= "https://avatars.githubusercontent.com/#{author['github']}"
          
          author
        end
        
        def guess_github_username(email, name)
          if email =~ /^([^@]+)@users\.noreply\.github\.com$/
            return $1
          end
          
          nil
        end
      end
    end
  end
end
