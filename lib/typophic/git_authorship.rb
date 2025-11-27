# frozen_string_literal: true

require "yaml"
require "date"

module Typophic
  # Analyzes Git commit history to derive authorship metadata
  #
  # Usage:
  #   result = Typophic::GitAuthorship.analyze("content/posts/my-post.md")
  #   result[:primary_author]  # => "pankajdoharey"
  #   result[:contributors]    # => ["neerajdoharey", "metacritical"]
  #   result[:published_at]    # => "2023-01-15"
  #   result[:updated_at]      # => "2023-11-27"
  #
  module GitAuthorship
    class << self
      # Analyze Git history for a file and return authorship metadata
      #
      # @param file_path [String] Absolute or relative path to content file
      # @return [Hash, nil] Authorship data or nil if no Git history
      def analyze(file_path)
        return nil unless File.exist?(file_path)
        return nil unless git_repository?

        commits = git_log_for_file(file_path)
        return nil if commits.empty?

        emails = commits.map { |c| c[:email] }
        author_ids = emails.map { |email| email_to_author_id(email) }.compact.uniq

        return nil if author_ids.empty?

        # Primary author: first committer (chronologically oldest commit)
        primary_author_id = author_ids.first

        # Contributors: all other unique authors
        contributors = author_ids[1..-1] || []

        {
          primary_author: primary_author_id,
          contributors: contributors,
          published_at: parse_timestamp(commits.last[:timestamp]),  # Oldest commit
          updated_at: parse_timestamp(commits.first[:timestamp])    # Newest commit
        }
      end

      private

      # Check if we're in a Git repository
      def git_repository?
        @is_git_repo ||= system("git rev-parse --git-dir > /dev/null 2>&1")
      end

      # Get Git commit history for a specific file
      #
      # @param file_path [String] Path to file
      # @return [Array<Hash>] Array of {email:, timestamp:}
      def git_log_for_file(file_path)
        # Use --follow to track renames, format: "email|timestamp"
        cmd = "git log --follow --format='%ae|%at' -- #{Shellwords.escape(file_path)} 2>/dev/null"
        output = `#{cmd}`.strip

        return [] if output.empty?

        output.lines.map do |line|
          email, timestamp = line.strip.split("|", 2)
          { email: email, timestamp: timestamp.to_i }
        end
      rescue => e
        warn "GitAuthorship: Failed to get Git log for #{file_path}: #{e.message}"
        []
      end

      # Map Git commit email to author ID using data/authors.yml
      #
      # @param email [String] Git commit email
      # @return [String, nil] Author ID or nil if unmapped
      def email_to_author_id(email)
        return nil if email.nil? || email.strip.empty?

        authors = load_authors
        email_normalized = email.strip.downcase

        authors.each do |author_id, data|
          next unless data.is_a?(Hash)
          
          emails = Array(data["emails"] || data[:emails])
          emails_normalized = emails.map { |e| e.to_s.strip.downcase }

          return author_id if emails_normalized.include?(email_normalized)
        end

        # Email not found in authors.yml
        warn "GitAuthorship: Unknown email '#{email}' - add to data/authors.yml"
        nil
      end

      # Load authors.yml (cached for performance)
      #
      # @return [Hash] Authors data
      def load_authors
        @authors_cache ||= begin
          authors_path = "data/authors.yml"
          
          if File.exist?(authors_path)
            YAML.safe_load(File.read(authors_path), permitted_classes: [Date], aliases: true) || {}
          else
            {}
          end
        rescue => e
          warn "GitAuthorship: Failed to load #{authors_path}: #{e.message}"
          {}
        end
      end

      # Parse Unix timestamp to YYYY-MM-DD string
      #
      # @param timestamp [Integer] Unix timestamp
      # @return [String] Date in YYYY-MM-DD format
      def parse_timestamp(timestamp)
        return nil unless timestamp

        Time.at(timestamp).strftime("%Y-%m-%d")
      rescue => e
        warn "GitAuthorship: Failed to parse timestamp #{timestamp}: #{e.message}"
        nil
      end
    end
  end
end

# Load Shellwords for safe command escaping
require "shellwords"
