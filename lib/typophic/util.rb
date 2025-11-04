# frozen_string_literal: true

module Typophic
  module Util
    module_function

    def sanitize_slug(text)
      text.to_s.downcase.gsub(/[^a-z0-9]+/, "-").gsub(/^-|-$/, "")
    end

    def git_config(key)
      value = `git config --get #{key}`.to_s.strip
      value.empty? ? nil : value
    rescue
      nil
    end

    def git_remote_origin
      url = `git remote get-url origin`.to_s.strip
      url.empty? ? nil : url
    rescue
      nil
    end

    def github_username_from_remote(remote)
      return nil unless remote
      # Support git@github.com:owner/repo.git or https://github.com/owner/repo.git
      if remote =~ %r{github\.com[:/](?<owner>[^/]+)/}
        Regexp.last_match(:owner)
      end
    end

    def resolved_author(fallback: "Typophic User")
      name = git_config("user.name")
      email = git_config("user.email")
      gh = github_username_from_remote(git_remote_origin)
      if name && email
        gh ? "#{name} (@#{gh}) <#{email}>" : "#{name} <#{email}>"
      else
        fallback
      end
    end
  end
end

