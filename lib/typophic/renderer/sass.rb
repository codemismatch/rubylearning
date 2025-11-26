require "sass-embedded"

module Typophic
  module Renderer
    class Sass
      def initialize(load_paths = [])
        @load_paths = load_paths
      end

      def compile(content, syntax: :scss, filename: nil)
        # Strip front matter headers before compiling
        if content =~ /\A---\s*\n.*?\n---\s*\n/m
          content = content.sub(/\A---\s*\n.*?\n---\s*\n/m, "")
        end

        ::Sass.compile_string(
          content,
          load_paths: @load_paths,
          syntax: syntax,
          style: :compressed
        ).css
      rescue => e
        label = filename ? " in #{filename}" : ""
        puts "  ❌ Sass compilation error#{label}: #{e.message}"
        nil
      end
    end
  end
end
