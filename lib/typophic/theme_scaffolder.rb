# frozen_string_literal: true

require "fileutils"

module Typophic
  class ThemeScaffolder
    def self.generate(root_path:, theme_name:, site_name:, description:, author: "Typophic User")
      theme_root = File.join(root_path, "themes", theme_name)
      directories = %w[layouts includes css js images].map { |dir| File.join(theme_root, dir) }

      directories.each { |dir| FileUtils.mkdir_p(dir) }

      write_file(File.join(theme_root, "layouts", "default.html"), default_layout_html(site_name))
      write_file(File.join(theme_root, "css", "style.css"), default_stylesheet)
      write_file(File.join(theme_root, "js", "site.js"), default_script)
      write_file(File.join(theme_root, "includes", "_head.html"), head_partial(site_name, description))
      write_file(File.join(theme_root, "includes", "_footer.html"), footer_partial(author))
    end

    def self.write_file(path, contents)
      return if File.exist?(path)

      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, contents)
    end
    private_class_method :write_file

    def self.default_layout_html(site_name)
      <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <%= render_partial 'head' %>
        </head>
        <body>
          <header class="site-header">
            <div class="container">
              <h1><a href="<%= url_for('/') %>">#{site_name}</a></h1>
              <nav class="site-nav">
                <a href="<%= url_for('/') %>">Home</a>
                <a href="<%= url_for('pages/about/') %>">About</a>
                <a href="<%= url_for('posts/') %>">Posts</a>
              </nav>
            </div>
          </header>
          <main class="container">
            <%= content %>
          </main>
          <footer class="site-footer">
            <%= render_partial 'footer' %>
          </footer>
          <script src="<%= asset_path('js/site.js') %>" defer></script>
        </body>
        </html>
      HTML
    end
    private_class_method :default_layout_html

    def self.default_stylesheet
      <<~CSS
        :root {
          color-scheme: light dark;
        }

        body {
          margin: 0;
          font-family: system-ui, -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
          color: #101828;
          background-color: #f8fafc;
        }

        a {
          color: #2563eb;
          text-decoration: none;
        }

        a:hover {
          text-decoration: underline;
        }

        .container {
          max-width: 960px;
          margin: 0 auto;
          padding: 1.5rem;
        }

        .site-header {
          background: #0f172a;
          color: #f8fafc;
        }

        .site-nav a {
          margin-right: 1rem;
        }

        .site-footer {
          border-top: 1px solid #e2e8f0;
          text-align: center;
          padding: 1.5rem 0;
          color: #64748b;
        }
      CSS
    end
    private_class_method :default_stylesheet

    def self.default_script
      <<~JS
        document.addEventListener('DOMContentLoaded', () => {
          console.log('Typophic theme ready.');
        });
      JS
    end
    private_class_method :default_script

    def self.head_partial(site_name, description)
      <<~HTML
        <meta charset="UTF-8" />
        <meta name="viewport" content="width=device-width, initial-scale=1" />
        <title><%= page.title %> - #{site_name}</title>
        <meta name="description" content="<%= page.description || '#{description}' %>" />
        <link rel="stylesheet" href="<%= asset_path('css/style.css') %>" />
      HTML
    end
    private_class_method :head_partial

    def self.footer_partial(author)
      <<~HTML
        <div class="container">
          <p>&copy; <%= Time.now.year %> #{author}. Built with Typophic.</p>
        </div>
      HTML
    end
    private_class_method :footer_partial
  end
end

