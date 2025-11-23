# frozen_string_literal: true

require "cgi"

module Typophic
  module Renderer
    # Lightweight Markdown renderer tuned for Typophic content.
    # Mirrors the Crystal pipeline so block-level transforms behave
    # identically across both implementations.
    class Markdown
      CODE_WINDOW_TOKEN = "\x00CODE_WINDOW_%<idx>d\x00"
      PRE_TOKEN         = "\x00PRE_%<idx>d\x00"
      SCRIPT_TOKEN      = "\x00SCRIPT_%<idx>d\x00"
      PRACTICE_TOKEN    = "\x00PRACTICE_DIV_%<idx>d\x00"

      def initialize(content, code_window_builder:)
        @content = content.dup
        @code_window_builder = code_window_builder
        @code_windows = []
        @pre_blocks   = []
        @script_blocks = []
        @practice_divs = []
      end

      def render
        handle_code_fences
        protect_blocks
        transform_headings
        transform_horizontal_rules
        wrap_paragraphs
        remove_block_paragraphs
        close_heading_tags
        render_bold_text
        render_inline_code
        render_links
        render_lists
        restore_blocks

        "<div class='markdown'>#{@content}</div>"
      end

      private

      attr_reader :code_window_builder

      def handle_code_fences
        regex = /```([a-z-]*)[ \t]*\r?\n([\s\S]*?)```/m
        @content = @content.gsub(regex) do
          lang = Regexp.last_match(1).to_s
          body = Regexp.last_match(2).to_s.rstrip

          case lang
          when "ruby-exec"
            build_code_window("ruby", body, executable: true)
          when "solution", "test"
            Regexp.last_match(0)
          else
            language = lang.empty? ? nil : lang
            build_code_window(language, body, executable: false)
          end
        end
      end

      def protect_blocks
        protect_code_windows
        protect_pre_blocks
        protect_script_blocks
        protect_practice_feedback
      end

      def protect_code_windows
        regex = /<div[^>]*class="code-window"[^>]*>[\s\S]*?<\/div>/m
        @content = @content.gsub(regex) do |block|
          token = format(CODE_WINDOW_TOKEN, idx: @code_windows.length)
          @code_windows << block
          token
        end
      end

      def protect_pre_blocks
        regex = /<pre[^>]*>[\s\S]*?<\/pre>/m
        @content = @content.gsub(regex) do |block|
          token = format(PRE_TOKEN, idx: @pre_blocks.length)
          @pre_blocks << block
          token
        end
      end

      def protect_script_blocks
        regex = /<script[^>]*>[\s\S]*?<\/script>/m
        @content = @content.gsub(regex) do |block|
          token = format(SCRIPT_TOKEN, idx: @script_blocks.length)
          @script_blocks << block
          token
        end
      end

      def protect_practice_feedback
          regex = /<div[^>]*class="practice-feedback"[^>]*>[\s\S]*?<\/div>/m
          @content = @content.gsub(regex) do |block|
            token = format(PRACTICE_TOKEN, idx: @practice_divs.length)
            @practice_divs << block
            token
          end
      end

      def transform_headings
        regex = /(^|\n)(#+)\s+(.+)/
        @content = @content.gsub(regex) do
          prefix = Regexp.last_match(1).to_s
          marks  = Regexp.last_match(2).to_s
          heading_text = Regexp.last_match(3).to_s
          slug = nil

          if heading_text =~ /\s*\{#([^}]+)\}\s*$/
            slug = Regexp.last_match(1)
            heading_text = heading_text.sub(/\s*\{#([^}]+)\}\s*$/, "")
          end

          heading_text = heading_text.strip
          level = marks.length
          rendered = if slug
                       %(<h#{level} id="#{slug}">#{heading_text}</h#{level}>)
                     else
                       %(<h#{level}>#{heading_text}</h#{level}>)
                     end

          "#{prefix}#{rendered}"
        end
      end

      def transform_horizontal_rules
        @content = @content.gsub(/^---\s*$/m, "<hr />")
      end

      def wrap_paragraphs
        @content = "<p>#{@content}</p>"
        @content = @content.gsub(/<\/p>\s*\n+\s*<p>/, "</p>\n<p>")
      end

      def remove_block_paragraphs
        block_regex = /<p>(<\/?(?:h[1-6]|pre|ul|ol|li|div|p|script|hr)[^>]*>)<\/p>/m
        closing_regex = /<p>\s*(<\/(?:h[1-6]|pre|ul|ol|li|div|p|script|hr)>)\s*<\/p>/m
        @content = @content.gsub(block_regex, "\\1")
        @content = @content.gsub(closing_regex, "\\1")
      end

      def close_heading_tags
        regex = /<(h[1-6])>([^<\r\n]*)(\r?\n)/
        @content = @content.gsub(regex) do
          tag = Regexp.last_match(1)
          text = Regexp.last_match(2)
          newline = Regexp.last_match(3)
          "<#{tag}>#{text}</#{tag}>#{newline}"
        end
      end

      def render_bold_text
        @content = @content.gsub(/\*\*([^*]+)\*\*/) do
          %(<strong>#{Regexp.last_match(1)}</strong>)
        end
      end

      def render_inline_code
        @content = @content.gsub(/`([^`]+)`/) do
          code_content = Regexp.last_match(1)
          code_content = code_content.gsub("<", "&lt;").gsub(">", "&gt;")
          "<code>#{code_content}</code>"
        end
      end

      def render_links
        regex = /\[([^\]]+)\]\(([^\)]+)\)/
        @content = @content.gsub(regex) do
          text = Regexp.last_match(1)
          url = Regexp.last_match(2)
          %(<a href="#{url}">#{text}</a>)
        end
      end

      def render_lists
        # convert "- item" lines into <li>
        @content = @content.gsub(/^\-\s+(.+)$/m) do
          "<li>#{Regexp.last_match(1)}</li>"
        end

        wrapper_regex = /(?:\A|\n)(<li>.+?<\/li>)(?=\n|\z)/m
        @content = @content.gsub(wrapper_regex) do
          "<ul>#{Regexp.last_match(1)}</ul>"
        end
      end

      def restore_blocks
        restore_collection(@practice_divs, PRACTICE_TOKEN)
        restore_collection(@script_blocks, SCRIPT_TOKEN)
        restore_collection(@pre_blocks, PRE_TOKEN)
        restore_collection(@code_windows, CODE_WINDOW_TOKEN)
      end

      def restore_collection(collection, token_template)
        collection.each_with_index do |block, idx|
          token = format(token_template, idx: idx)
          @content = @content.gsub(token, block)
        end
      end

      def build_code_window(language, code_body, executable:)
        code_window_builder.call(language, code_body, executable)
      end
    end
  end
end
