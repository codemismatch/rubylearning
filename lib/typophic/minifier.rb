# frozen_string_literal: true

begin
  require "htmlcompressor"
rescue LoadError
  warn "Warning: htmlcompressor gem not found. HTML minification will be skipped."
end

begin
  require "terser"
rescue LoadError
  warn "Warning: terser gem not found. JavaScript minification will be skipped."
end

begin
  require "autoprefixer-rails"
rescue LoadError
  warn "Warning: autoprefixer-rails gem not found. CSS autoprefixing will be skipped."
end

module Typophic
  # Minifies HTML, CSS, and JavaScript files for production builds
  class Minifier
    class << self
      # Minify HTML content
      # @param html [String] HTML content to minify
      # @param options [Hash] Minification options
      # @return [String] Minified HTML
      def minify_html(html, options = {})
        return html unless defined?(HtmlCompressor)

        # Use simpler options that htmlcompressor gem supports
        compressor = HtmlCompressor::Compressor.new(
          remove_comments: options.fetch(:remove_comments, true),
          remove_multi_spaces: options.fetch(:remove_multi_spaces, true),
          remove_intertag_spaces: options.fetch(:remove_intertag_spaces, true),
          remove_quotes: options.fetch(:remove_quotes, false),
          compress_css: options.fetch(:compress_css, false),
          compress_javascript: options.fetch(:compress_javascript, false),
          simple_doctype: options.fetch(:simple_doctype, false),
          remove_script_attributes: options.fetch(:remove_script_attributes, false),
          remove_style_attributes: options.fetch(:remove_style_attributes, false),
          remove_link_attributes: options.fetch(:remove_link_attributes, false),
          remove_form_attributes: options.fetch(:remove_form_attributes, false),
          remove_input_attributes: options.fetch(:remove_input_attributes, false),
          remove_javascript_protocol: options.fetch(:remove_javascript_protocol, true),
          remove_http_protocol: options.fetch(:remove_http_protocol, false),
          remove_https_protocol: options.fetch(:remove_https_protocol, false),
          preserve_line_breaks: options.fetch(:preserve_line_breaks, false),
          # Mermaid diagram source must keep its line breaks — collapsing
          # them turns the diagram into a single-line syntax error.
          preserve_patterns: options.fetch(:preserve_patterns, [
            /<div class="mermaid"[\s\S]*?<\/div>/m,
            # htmlcompressor drops empty block elements; the Ruby console's
            # ghost <pre> is populated by JS at runtime and must survive.
            /<pre class="ruby-irb-ghost"><\/pre>/
          ])
        )
        result = compressor.compress(html.to_s)
        result.is_a?(String) ? result : html
      rescue => e
        warn "HTML minification failed: #{e.message}"
        html # Return original on failure
      end

      # Minify CSS content
      # @param css [String] CSS content to minify
      # @param options [Hash] Minification options
      # @return [String] Minified CSS
      def minify_css(css, options = {})
        # First apply autoprefixer if enabled and available
        if options[:autoprefix] != false && defined?(AutoprefixerRails)
          css = autoprefix_css(css, options[:browsers] || ["last 2 versions"])
        end

        # Then minify
        minified = css.dup
        # Remove comments (but preserve /*! comments for licenses)
        minified.gsub!(%r{/\*(?!!)[^*]*\*+(?:[^/*][^*]*\*+)*/}, "") if options.fetch(:remove_comments, true)
        # Remove whitespace
        minified.gsub!(/\s+/, " ") if options.fetch(:remove_whitespace, true)
        # Remove spaces around certain characters
        minified.gsub!(/\s*([{}:;,])\s*/, '\1') if options.fetch(:remove_whitespace, true)
        # Remove trailing semicolons before closing braces
        minified.gsub!(/;}/, "}") if options.fetch(:remove_trailing_semicolons, true)
        # Remove leading/trailing whitespace
        minified.strip
      rescue => e
        warn "CSS minification failed: #{e.message}"
        css # Return original on failure
      end

      # Minify JavaScript content
      # @param js [String] JavaScript content to minify
      # @param options [Hash] Minification options
      # @return [String] Minified JavaScript
      def minify_javascript(js, options = {})
        return js if options[:skip] == true
        return js unless defined?(Terser)

        terser_options = {
          compress: {
            drop_console: options.fetch(:drop_console, false),
            drop_debugger: options.fetch(:drop_debugger, true),
            pure_funcs: options.fetch(:pure_funcs, [])
          },
          mangle: options.fetch(:mangle, true),
          output: {
            comments: options.fetch(:preserve_comments, false) ? /^!/ : false
          }
        }

        result = Terser.new(terser_options).compile(js)
        result || js
      rescue => e
        warn "JavaScript minification failed: #{e.message}"
        js # Return original on failure
      end

      # Apply autoprefixer to CSS
      # @param css [String] CSS content
      # @param browsers [Array] Browser versions to support
      # @return [String] CSS with vendor prefixes
      def autoprefix_css(css, browsers = ["last 2 versions"])
        return css unless defined?(AutoprefixerRails)

        AutoprefixerRails.process(css, browsers: browsers).css
      rescue => e
        warn "Autoprefixer failed: #{e.message}"
        css # Return original on failure
      end
    end
  end
end
