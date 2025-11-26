# frozen_string_literal: true

module Protocss
  module Plugins
    module Tailwind
      class ContentScanner
        attr_reader :content_paths, :extracted_classes

        # Regex pattern to match Tailwind class names
        # Matches: class="...", className="...", class:list={...}, etc.
        CLASS_PATTERN = /
          (?:class|className)                    # class or className attribute
          \s*[=:]\s*                             # = or : separator
          (?:
            ["']([^"']*?)["']                    # quoted string
            |
            \{[^}]*?["']([^"']*?)["'][^}]*?\}    # JSX/Vue expression with quotes
            |
            \[([^\]]*?)\]                        # Array syntax
          )
        /x.freeze

        # Additional pattern for @apply directives in CSS
        APPLY_PATTERN = /@apply\s+([^;]+);?/

        # File extensions to scan
        SCANNABLE_EXTENSIONS = %w[
          html erb haml slim
          jsx tsx vue svelte
          php blade
          rb
        ].freeze

        def initialize(content_paths = [], options = {})
          @content_paths = normalize_paths(content_paths)
          @extracted_classes = Set.new
          @cache = {}
          @options = options
          @watch_mode = options[:watch] || false
        end

        def scan
          @extracted_classes.clear
          
          @content_paths.each do |path|
            if File.directory?(path)
              scan_directory(path)
            elsif File.file?(path)
              scan_file(path)
            else
              # Glob pattern
              Dir.glob(path).each { |file| scan_file(file) if File.file?(file) }
            end
          end

          @extracted_classes.to_a.sort
        end

        def scan_content(content)
          classes = Set.new

          # Extract from class attributes
          content.scan(CLASS_PATTERN) do |match|
            # match is an array of capture groups, find the non-nil one
            class_string = match.compact.first
            next unless class_string

            # Split by whitespace and extract individual classes
            class_string.split(/\s+/).each do |cls|
              classes.add(cls.strip) unless cls.strip.empty?
            end
          end

          # Extract from @apply directives
          content.scan(APPLY_PATTERN) do |match|
            match[0].split(/\s+/).each do |cls|
              classes.add(cls.strip) unless cls.strip.empty?
            end
          end

          # Handle dynamic classes like bg-${color}-500
          # Extract the static parts
          extract_dynamic_classes(content, classes)

          classes
        end

        def watch(&block)
          return unless @watch_mode

          require 'listen'

          dirs = @content_paths.select { |p| File.directory?(p) }
          return if dirs.empty?

          listener = Listen.to(*dirs) do |modified, added, removed|
            changed_files = (modified + added).select { |f| scannable_file?(f) }
            next if changed_files.empty?

            # Rescan and notify
            old_classes = @extracted_classes.dup
            scan
            new_classes = @extracted_classes - old_classes
            removed_classes = old_classes - @extracted_classes

            block.call(new_classes, removed_classes) if block_given?
          end

          listener.start
          listener
        end

        private

        def normalize_paths(paths)
          Array(paths).flat_map do |path|
            # Expand glob patterns
            if path.include?('*')
              Dir.glob(path)
            else
              path
            end
          end
        end

        def scan_directory(dir)
          Dir.glob(File.join(dir, '**', '*')).each do |file|
            next unless File.file?(file)
            scan_file(file) if scannable_file?(file)
          end
        end

        def scan_file(file)
          return unless scannable_file?(file)

          # Use cache if file hasn't changed
          mtime = File.mtime(file)
          if @cache[file] && @cache[file][:mtime] == mtime
            @extracted_classes.merge(@cache[file][:classes])
            return
          end

          content = File.read(file)
          classes = scan_content(content)
          
          @cache[file] = { mtime: mtime, classes: classes }
          @extracted_classes.merge(classes)
        rescue => e
          warn "Error scanning file #{file}: #{e.message}" if @options[:verbose]
        end

        def scannable_file?(file)
          ext = File.extname(file).delete_prefix('.')
          SCANNABLE_EXTENSIONS.include?(ext)
        end

        def extract_dynamic_classes(content, classes)
          # Pattern for template literals and string interpolation
          # e.g., `bg-${color}-500`, "text-#{size}-bold"
          dynamic_patterns = [
            /["'`]([a-z-]+)-\$\{[^}]+\}-([a-z0-9-]+)["'`]/,  # JS template literal
            /["']([a-z-]+)-#\{[^}]+\}-([a-z0-9-]+)["']/,     # Ruby interpolation
          ]

          dynamic_patterns.each do |pattern|
            content.scan(pattern) do |prefix, suffix|
              # We can't know the exact class, but we can note the pattern
              # For now, we'll skip these or add them to a separate collection
              # In a full implementation, you might want to generate all possible
              # combinations based on your theme config
            end
          end
        end
      end
    end
  end
end
