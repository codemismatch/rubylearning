#!/usr/bin/env ruby
# frozen_string_literal: true

# Tool to rebuild authors.yml from Git history and GitHub API
#
# Usage:
#   ruby tools/refresh_authors.rb
#   ruby tools/refresh_authors.rb --dry-run

require 'yaml'
require 'net/http'
require 'json'
require 'uri'

class AuthorsRefresher
  GITHUB_API_BASE = "https://api.github.com"
  AUTHORS_FILE = "data/authors.yml"
  
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
      
      # Check if we already have this author
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
      write_authors_file(authors_data)
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
    # Get all unique email/name combinations from Git
    output = `git log --all --format="%ae|%an" 2>/dev/null`
    
    commits = {}
    output.lines.each do |line|
      email, name = line.strip.split("|", 2)
      next if email.nil? || email.empty?
      
      # Normalize email
      email = email.downcase.strip
      commits[email] ||= name
    end
    
    commits
  end
  
  def email_to_author_id(email)
    # Convert email to author ID (username before @)
    username = email.split("@").first
    username.gsub(/[^a-z0-9]/, "").downcase
  end
  
  def update_existing_author(author_id, email)
    author = @existing_authors[author_id].dup
    
    # Add email if not already present
    emails = Array(author["emails"] || [])
    emails << email unless emails.include?(email)
    author["emails"] = emails.uniq.sort
    
    # Try to refresh GitHub data if GitHub username is set
    if author["github"]
      github_data = fetch_github_data(author["github"])
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
    # Try to guess GitHub username from email
    github_username = guess_github_username(email, name)
    
    author = {
      "github" => github_username || author_id,
      "emails" => [email],
      "name" => name,
      "avatar" => nil,
      "bio" => "Contributor",
      "cached_at" => Date.today.to_s
    }
    
    # Try to fetch from GitHub if we have a username
    if github_username
      github_data = fetch_github_data(github_username)
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
    
    # Fallback avatar if none from GitHub
    author["avatar"] ||= "https://avatars.githubusercontent.com/#{author['github']}"
    
    author
  end
  
  def guess_github_username(email, name)
    # Try common patterns:
    # 1. username@users.noreply.github.com -> username
    if email =~ /^([^@]+)@users\.noreply\.github\.com$/
      return $1
    end
    
    # 2. Check if email domain is github-related
    # For now, return nil and let user manually set it
    nil
  end
  
  def fetch_github_data(username)
    uri = URI("#{GITHUB_API_BASE}/users/#{username}")
    
    # Add GitHub token if available (for higher rate limits)
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
    warn "   ⚠️  GitHub API error: #{e.message}"
    nil
  end
  
  def write_authors_file(authors_data)
    # Write with nice formatting
    content = "# Typophic Author Registry\n"
    content += "#\n"
    content += "# Purpose: Email-to-author-ID mapping + cached GitHub data\n"
    content += "#\n"
    content += "# Auto-generated by tools/refresh_authors.rb\n"
    content += "# Last updated: #{Time.now.strftime('%Y-%m-%d %H:%M:%S')}\n"
    content += "\n"
    content += YAML.dump(authors_data)
    
    File.write(AUTHORS_FILE, content)
  end
end

# Run the tool
if __FILE__ == $0
  dry_run = ARGV.include?("--dry-run")
  
  puts "=" * 60
  puts "  Typophic Authors Refresh Tool"
  puts "=" * 60
  puts ""
  
  refresher = AuthorsRefresher.new(dry_run: dry_run)
  refresher.run
  
  puts ""
  puts "=" * 60
  puts "  #{dry_run ? 'DRY RUN COMPLETE' : 'DONE'}"
  puts "=" * 60
end
