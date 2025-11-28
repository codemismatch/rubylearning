# frozen_string_literal: true

require "fileutils"
require "yaml"
require "date"
require "time"
require "json"
require "erb"
require "liquid"
require "uri"
require "ostruct"
require "set"
require "etc"
require "thread"

require_relative "tutorial_formatter"
require_relative "pipeline"
require_relative "renderer/markdown"
require_relative "renderer/liquid"
require_relative "renderer/sass"
require_relative "renderer/protocss"
require_relative "renderer/diagram"

module Typophic
  # Core static-site builder that transforms Markdown content and ERB templates
  # into a fully-linked static site. The goal is to generate correct URLs and
  # asset paths on the first pass—no post-build fixers required.
  class Builder
    attr_reader :source_dir,
                :output_dir,
                :theme_root,
                :theme_name,
                :theme_path,
                :default_theme_name,
                :theme_paths,
                :data_dir,
                :site_layouts_dir,
                :site_includes_dir,
                :site_assets_dir,
                :sass_renderer,
                :protocss_renderer

    SUPPORTED_CONTENT_EXTENSIONS = %w[.md .markdown .html .htm .erb .liquid].freeze

    def initialize(options = {})
      @source_dir   = options[:source_dir] || "content"
      @output_dir   = options[:output_dir] || "public"
      @theme_root   = options[:theme_root] || "themes"
      @data_dir     = options[:data_dir] || "data"
      @site_layouts_dir  = options[:layouts_dir]  || "layouts"
      @site_includes_dir = options[:includes_dir] || "includes"
      @site_assets_dir   = options[:assets_dir]   || "assets"
      @parallel     = options.fetch(:parallel, true)
      @thread_count = options.fetch(:thread_count, [Etc.nprocessors, 4].min)
      @verbose      = options.fetch(:verbose, true)

      @config = load_config

      configure_themes(options)

      @site       = build_site_context(@config)
      @collections = Hash.new { |hash, key| hash[key] = [] }
      @archives    = Hash.new { |hash, key| hash[key] = [] }
      @taxonomies  = { tags: Hash.new { |hash, key| hash[key] = [] } }
      @helper_modules = load_helpers
    end

    def build
      start_time = Time.now
      puts "Building site#{@parallel ? " (parallel: #{@thread_count} threads)" : " (sequential)"}..."

      normalize_content_quotes

      FileUtils.rm_rf(Dir.glob(File.join(@output_dir, "*")))

      collect_content_theme_overrides
      copy_static_assets
      process_content_files
      write_collection_indexes

      elapsed = Time.now - start_time
      puts "Site built successfully! (#{elapsed.round(2)}s)"
    end

    private

    def normalize_content_quotes
      content_root = @source_dir || "content"
      target_exts = [".md", ".markdown"]
      smart_map = {
        "\u201C" => '"',
        "\u201D" => '"',
        "\u2018" => "'",
        "\u2019" => "'",
        "\u2013" => "-",
        "\u2014" => "-"
      }.freeze

      Dir.glob(File.join(content_root, "**", "*")).each do |path|
        next unless File.file?(path)
        ext = File.extname(path).downcase
        next unless target_exts.include?(ext)

        begin
          original = File.read(path, mode: "r:BOM|UTF-8")
          normalized = original.dup
          smart_map.each { |from, to| normalized.gsub!(from, to) }
          next if normalized == original

          File.write(path, normalized)
          puts "Normalized quotes in: #{path}"
        rescue Encoding::InvalidByteSequenceError, Encoding::UndefinedConversionError => e
          warn "Skipping #{path} due to encoding error: #{e.message}"
        end
      end
    end

    def configure_themes(options)
      config_theme = @config["theme"]
      case config_theme
      when String
        @default_theme_name = options[:theme] || config_theme
        @section_theme_map = {}
      when Hash
        @default_theme_name = (options[:theme] || config_theme["default"] || config_theme[:default] || "rubylearning").to_s
        sections = config_theme["sections"] || config_theme[:sections] || {}
        @section_theme_map = sections.transform_keys(&:to_s).transform_values(&:to_s)
      else
        @default_theme_name = options[:theme] || "rubylearning"
        @section_theme_map = {}
      end

      @theme_name = @default_theme_name
      @theme_path = File.join(@theme_root, @default_theme_name)

      names = Set.new([@default_theme_name])
      @section_theme_map.each_value { |n| names << n }
      # Ensure canonical fallback is available when present
      names << "rubylearning" if Dir.exist?(File.join(@theme_root, "rubylearning"))
      @theme_paths = names.each_with_object({}) { |n, memo| memo[n] = File.join(@theme_root, n) }

      @theme_paths.each do |name, path|
        raise "Theme '#{name}' not found at #{path}" unless Dir.exist?(path)
      end
      
      # Setup Sass renderer
      sass_paths = []
      @theme_paths.each_value do |path|
        %w[_sass assets/_sass assets/css assets/scss].each do |relative|
          candidate = File.join(path, relative)
          sass_paths << candidate if Dir.exist?(candidate)
        end
      end
      # Also add site _sass if exists
      %w[_sass assets/_sass assets/css assets/scss].each do |relative|
        candidate = File.join(@source_dir, relative)
        sass_paths << candidate if Dir.exist?(candidate)
      end

      @sass_renderer = Typophic::Renderer::Sass.new(sass_paths)

      protocss_config = @config["protocss"] || {}
      tailwind_config = protocss_config["tailwind_config"]
      @protocss_renderer = Typophic::Renderer::Protocss.new(tailwind_config: tailwind_config)
      css_allowlist = protocss_config["css"] || protocss_config[:css]
      @protocss_css_patterns = Array(css_allowlist).map(&:to_s)
    end

    

    def collect_content_theme_overrides
      Dir.glob(File.join(@source_dir, "**", "*.{md,markdown,html,erb}")) do |file|
        front_matter, = extract_front_matter(File.read(file))
        if (theme_name = front_matter["theme"]).to_s.strip != ""
          @theme_paths[theme_name] ||= File.join(@theme_root, theme_name) if Dir.exist?(File.join(@theme_root, theme_name))
        end
      rescue => _e
        # ignore parse errors; normal rendering will surface problems
      end
    end

    

        

    

    def theme_asset_destination(theme_name, asset_dir)
      File.join("themes", theme_name, asset_dir)
    end

    

        

    

    def load_config
      config = File.exist?("config.yml") ? YAML.load_file("config.yml") : {}

      # Merge theme configuration if available
      if config["theme"]
        theme_name = config["theme"].is_a?(Hash) ? config["theme"]["default"] : config["theme"]
        # @theme_root is initialized in initialize, but load_config is called inside initialize.
        # We need to use the passed options or default.
        # But load_config doesn't take options.
        # We can use @theme_root if it's already set?
        # initialize calls load_config BEFORE setting @theme_root?
        # No, @theme_root is set BEFORE load_config in initialize.
        
        theme_config_path = File.join(@theme_root, theme_name, "_config.yml")
        if File.exist?(theme_config_path)
          puts "Merging theme configuration from #{theme_config_path}"
          theme_config = YAML.load_file(theme_config_path) || {}
          # Simple merge (theme defaults + user overrides)
          # Note: For deep merge, we'd need a helper, but top-level merge covers most cases.
          config = theme_config.merge(config)
        end
      end

      override = ENV["TYPOPHIC_URL_OVERRIDE"].to_s.strip
      config["url"] = override unless override.empty?
      config
    rescue Errno::ENOENT
      {}
    end

    def load_data_files
      data_dir = @data_dir || "data"
      data = {}
      
      return data unless Dir.exist?(data_dir)
      
      Dir.glob(File.join(data_dir, "**", "*.{yaml,yml,json}")) do |file|
        relative_path = file.sub(/^#{Regexp.escape(data_dir)}\//, "")
        data_name = File.basename(relative_path, File.extname(relative_path))
        
        begin
          case File.extname(file).downcase
          when '.yaml', '.yml'
            content = YAML.safe_load(File.read(file), permitted_classes: [Date], aliases: true)
          when '.json'
            content = JSON.parse(File.read(file))
          else
            next
          end
          
          data[data_name] = content
        rescue => e
          puts "Warning: Could not load data file #{file}: #{e.message}"
        end
      end
      
      data
    end

    def build_site_context(config)
      base_url = config.fetch("url", "").to_s.strip
      base_url = base_url.chomp("/") unless base_url.empty?

      uri = begin
        base_url.empty? ? URI.parse("/") : URI.parse(base_url)
      rescue URI::InvalidURIError
        URI.parse("/")
      end

      base_path = uri.path.to_s
      base_path = "" if base_path == "/"

      # Load data files to make them available in templates similar to Hugo's .Site.Data
      data_files = load_data_files

      config.merge(
        "base_url" => base_url,
        "base_path" => base_path,
        "title" => config["site_name"] || config["title"] || "Typophic Site",
        "data" => data_files
      )
    end

    def copy_static_assets
      copy_tasks = []
      
      asset_dirs = %w[css js images assets]

      @theme_paths.each do |theme_name, path|
        asset_dirs.each do |asset_dir|
          copy_tasks << [File.join(path, asset_dir), theme_asset_destination(theme_name, asset_dir), "theme: #{theme_name}"]
        end
      end

      # Back-compat: also copy the default theme to root-level asset dirs
      asset_dirs.each do |asset_dir|
        copy_tasks << [File.join(@theme_path, asset_dir), asset_dir, "default theme (root)"]
      end

      asset_dirs.each do |asset_dir|
        copy_tasks << [File.join(@site_assets_dir, asset_dir), asset_dir, "site"]
      end

      if @parallel && copy_tasks.length > 1
        copy_assets_parallel(copy_tasks)
      else
        copy_tasks.each { |source, dest, label| copy_asset_tree(source, dest, label) }
      end
    end

    def copy_assets_parallel(copy_tasks)
      queue = Queue.new
      copy_tasks.each { |task| queue << task }

      threads = Array.new([@thread_count, copy_tasks.length].min) do
        Thread.new do
          while (task = queue.pop(true) rescue nil)
            source, dest, label = task
            copy_asset_tree(source, dest, label)
          end
        end
      end

      threads.each(&:join)
    end

    def copy_asset_tree(source, destination_dir, label)
      return unless Dir.exist?(source)

      destination = File.join(@output_dir, destination_dir)
      FileUtils.mkdir_p(destination)

      files = Dir.glob(File.join(source, "**", "*")).select { |f| File.file?(f) }
      return if files.empty?

      files.each do |file|
        relative = file.delete_prefix("#{source}/")
        target = File.join(destination, relative)
        FileUtils.mkdir_p(File.dirname(target))
        
        if file =~ /\.s[ac]ss$/
          # Compile SCSS/Sass
          target = target.sub(/\.s[ac]ss$/, ".css")
          content = File.read(file)
          
          # Check for front matter and render Liquid if present
          if content =~ /\A---\s*\n/
            front_matter, body = extract_front_matter(content)
            content = render_liquid_asset(body, relative, label)
          end
          
          syntax = file.end_with?(".sass") ? :sass : :scss
          
          css = @sass_renderer.compile(content, syntax: syntax, filename: file)
          if css
            File.write(target, css)
          else
            warn "  ⚠️ Failed to compile #{relative}"
          end
        elsif file.end_with?(".pcss")
          target = target.sub(/\.pcss$/, ".css")
          content = File.read(file)
          if content =~ /\A---\s*\n/
            front_matter, body = extract_front_matter(content)
            content = render_liquid_asset(body, relative, label)
          end
          compiled = compile_with_protocss(content, from: file, to: target)
          File.write(target, compiled || content)
        elsif file.end_with?(".css")
          content = File.read(file)
          if content =~ /\A---\s*\n/
            # Process CSS with Liquid if front matter is present
            front_matter, body = extract_front_matter(content)
            content = render_liquid_asset(body, relative, label)
          end
          if use_protocss_for_css?(relative)
            compiled = compile_with_protocss(content, from: file, to: target)
            File.write(target, compiled || content)
          else
            File.write(target, content)
          end
        else
          FileUtils.cp(file, target)
        end
      end

      puts "Copied #{files.length} #{label} asset(s)" if @verbose
    end

    private

    def render_liquid_asset(body, relative_path, label)
      # Determine theme name from label
      theme_name = if label.start_with?("theme: ")
                     label.sub("theme: ", "")
                   elsif label == "default theme (root)"
                     @default_theme_name
                   else
                     nil
                   end
      
      theme_includes = @theme_paths[theme_name] ? File.join(@theme_paths[theme_name], "includes") : nil

      page_context = { "path" => relative_path, "url" => "/#{relative_path}" }
      
      renderer = Typophic::Renderer::Liquid.new(
        content: "",
        site: @site,
        page: page_context,
        current_theme: theme_name,
        site_includes_dir: @site_includes_dir,
        theme_includes_dir: theme_includes,
        builder: self
      )
      renderer.render(body)
    end

    def compile_with_protocss(content, from:, to:)
      return content unless @protocss_renderer

      css = @protocss_renderer.compile(content, from: from, to: to)
      css || content
    end

    def use_protocss_for_css?(relative_path)
      return false unless @protocss_css_patterns && !@protocss_css_patterns.empty?

      @protocss_css_patterns.any? do |pattern|
        pattern == "*" || File.fnmatch?(pattern, relative_path, File::FNM_PATHNAME | File::FNM_EXTGLOB)
      end
    end

    def process_content_files
      files = Dir.glob(File.join(@source_dir, "**", "*"))
                 .select { |path| File.file?(path) && supported_content_file?(path) }
                 .sort

      # Filter out drafts from the file list (anything under content/…/drafts/…)
      # UNLESS we're in draft preview mode
      include_drafts = ENV["INCLUDE_DRAFTS"] == "true" || ENV["TYPOPHIC_INCLUDE_DRAFTS"] == "true"
      
      unless include_drafts
        files.reject! {|f| f.include?("/drafts/")}
      end

      entries = @parallel ? process_content_files_parallel(files) : process_content_files_sequential(files)

      # Remove any nil entries that may have been returned
      entries.compact!

      # Filter out draft entries from front matter (draft: true)
      # UNLESS we're in draft preview mode
      unless include_drafts
        entries.reject! { |entry| entry[:meta]&.fetch("draft", false) }
      else
        # Mark drafts for template rendering
        entries.each do |entry|
          next unless entry[:meta]
          # Check if the file path contains "/drafts/" or if front matter marks it as a draft
          if entry[:meta]["draft"] || entry[:file].to_s.include?("/drafts/")
            entry[:meta]["is_draft"] = true
          end
        end
      end

      entries
    end

    def process_content_files_sequential(files)
      entries = files.map { |file| parse_page(file) }

      entries.each { |entry| index_page(entry[:meta]) }
      inject_collection_data_into_site

      entries.each { |entry| render_page(entry) }
    end

    def process_content_files_parallel(files)
      # Phase 1: Parse all files in parallel
      entries = parse_files_parallel(files)

      # Phase 2: Index pages (must be sequential due to shared state)
      entries.each { |entry| index_page(entry[:meta]) }
      inject_collection_data_into_site

      # Phase 3: Render pages in parallel
      render_pages_parallel(entries)
    end

    def parse_files_parallel(files)
      entries = []
      mutex = Mutex.new
      queue = Queue.new
      files.each { |f| queue << f }

      threads = Array.new(@thread_count) do
        Thread.new do
          while (file = queue.pop(true) rescue nil)
            entry = parse_page(file)
            mutex.synchronize { entries << entry }
          end
        end
      end

      threads.each(&:join)
      entries.sort_by { |e| e[:meta]["source"] }
    end

    def render_pages_parallel(entries)
      queue = Queue.new
      entries.each { |e| queue << e }

      threads = Array.new(@thread_count) do
        Thread.new do
          while (entry = queue.pop(true) rescue nil)
            render_page(entry)
          end
        end
      end

      threads.each(&:join)
    end

    def parse_page(file)
      raw = File.read(file)
      front_matter, body = extract_front_matter(raw)
      renderer = renderer_for(file)
      meta = build_page_context(file, front_matter)

      { meta: meta, body: body, renderer: renderer }
    end

    def render_page(entry)
      page = entry[:meta]
      theme_name = theme_for_page(page)
      page["theme"] = theme_name
      # # puts "[DEBUG] Rendering #{page["source"]} with theme=#{theme_name} layout=#{page["layout"]}" if @verbose
      html_content = case entry[:renderer]
                     when :markdown
                       run_content_pipeline(page, entry[:body])
                     when :erb
                       render_inline_template(entry[:body], page, theme_name)
                     when :html
                       entry[:body]
                     else
                       entry[:body].to_s
                     end
      rendered = render_layout(page["layout"], html_content, page, theme_name)

      output_path = File.join(@output_dir, page["output_path"])
      FileUtils.mkdir_p(File.dirname(output_path))
      File.write(output_path, rendered, encoding: Encoding::UTF_8)

      puts "Generated: #{output_path}" if @verbose
    end

    def format_tutorials
      formatted = Typophic::TutorialFormatter.format_all(root: Dir.pwd)
      formatted.each { |path| puts "Formatted tutorial: #{path}" }
    end

    def supported_content_file?(path)
      return true if path.end_with?(".html.erb")

      ext = File.extname(path).downcase
      SUPPORTED_CONTENT_EXTENSIONS.include?(ext)
    end

    def renderer_for(path)
      return :erb if path.end_with?(".html.erb")
      return :liquid if path.end_with?(".liquid")

      case File.extname(path).downcase
      when ".md", ".markdown"
        :markdown
      when ".html", ".htm"
        :html
      when ".erb"
        :erb
      when ".liquid"
        :liquid
      else
        :markdown
      end
    end

    def strip_supported_extensions(filename)
      base = filename.dup
      base = base.sub(/\.html\.erb\z/i, "")
      base = base.sub(/\.(md|markdown|html|htm|erb|liquid)\z/i, "")
      base
    end

    def load_helpers
      helper_dirs = ["helpers"] + @theme_paths.values.map { |p| File.join(p, "helpers") }
      helper_modules = []

      helper_dirs.each do |dir|
        next unless Dir.exist?(dir)

        Dir.glob(File.join(dir, "**", "*.rb")).sort.each do |file|
          require File.expand_path(file)
        end
      end

      if defined?(Typophic::Helpers)
        Typophic::Helpers.constants.each do |const|
          mod = Typophic::Helpers.const_get(const)
          helper_modules << mod if mod.is_a?(Module)
        end
      end

      helper_modules
    end

    def extract_front_matter(raw)
      if raw =~ /\A---\s*\n(.*?)---\s*\n(.*)/m
        yaml_content = Regexp.last_match(1)
        data = if yaml_content.strip.empty?
                 {}
               else
                 YAML.safe_load(
                   yaml_content,
                   permitted_classes: [Date, Time],
                   aliases: true
                 ) || {}
               end
        [data, Regexp.last_match(2)]
      else
        [{}, raw]
      end
    end

    def build_page_context(file, front_matter)
      relative_source = file.sub(/^#{@source_dir}\//, "")
      segments = relative_source.split(File::SEPARATOR)
      section = segments.first || ""
      filename = segments.last || "index.md"
      stem = strip_supported_extensions(filename)

      slug, inferred_date = derive_slug_and_date(stem, front_matter)
      layout = (front_matter["layout"] || default_layout_for(section)).to_s

      # Support Hugo-like content types
      content_type = front_matter["type"] || section

      permalink = front_matter["permalink"]
      permalink = default_permalink(section, segments[1..-2], slug, filename) if permalink.nil? || permalink.empty?
      permalink = normalize_permalink(permalink)

      page = stringify_keys(front_matter)
      page["layout"] = layout
      page["section"] = section
      page["draft"] = !!page["draft"]
      page["type"] = content_type  # Add Hugo-like content type
      page["source"] = relative_source
      page["slug"] = slug
      
      # Auto-populate authorship from Git (unless it's a draft)
      unless page["draft"]
        begin
          require_relative "git_authorship" unless defined?(Typophic::GitAuthorship)
          git_info = Typophic::GitAuthorship.analyze(file)
          
          if git_info
            # Only set if not manually specified in frontmatter
            page["author"] ||= git_info[:primary_author]
            
            # Set contributors if there are any (excluding primary author)
            if git_info[:contributors]&.any?
              page["contributors"] = git_info[:contributors]
            end
            
            # Use Git date if no date in frontmatter or filename
            page["date"] ||= git_info[:published_at] if git_info[:published_at]
            
            # Always set updated_at if it differs from published
            if git_info[:updated_at] && git_info[:updated_at] != git_info[:published_at]
              page["updated_at"] = git_info[:updated_at]
            end
          end
        rescue => e
          # Gracefully handle Git analysis failures (e.g., not a Git repo)
          warn "Git authorship analysis failed for #{file}: #{e.message}" if @verbose
        end
      end
      
      page["date"] ||= inferred_date
      page["date"] = parse_date(page["date"])
      page["date_iso"] = page["date"]&.strftime("%Y-%m-%d")
      page["permalink"] = permalink
      page["url"] = build_url(permalink)
      page["output_path"] = build_output_path(permalink)
      page["title"] ||= prettify_slug(slug)
      page["tags"] = Array(page["tags"])

      page
    end

    def theme_for_page(page)
      return page["theme"].to_s unless page["theme"].to_s.strip.empty?
      section = page["section"].to_s
      return @section_theme_map[section] if @section_theme_map && @section_theme_map[section]
      @default_theme_name
    end

    def default_layout_for(section)
      section == "posts" ? "post" : "page"
    end

    def derive_slug_and_date(stem, front_matter)
      if stem =~ /(\d{4}-\d{2}-\d{2})-(.+)/
        [Regexp.last_match(2), front_matter["date"] || Regexp.last_match(1)]
      else
        [stem, front_matter["date"]]
      end
    end

    def default_permalink(section, intermediate_segments, slug, filename)
      case section
      when "posts"
        "/posts/#{slug}/"
      when "pages"
        siblings = Array(intermediate_segments).dup
        if filename == "index.md" && siblings.empty?
          "/"
        elsif siblings.any?
          "/#{([section] + siblings + [slug]).join('/')}/"
        else
          "/pages/#{slug}/"
        end
      else
        filename == "index.md" ? "/" : "/#{slug}/"
      end
    end

    def normalize_permalink(permalink)
      normalized = permalink.to_s.strip
      normalized = "/#{normalized}" unless normalized.start_with?("/")
      normalized = normalized.gsub(%r{//+}, "/")
      normalized.end_with?("/") ? normalized : "#{normalized}/"
    end

    def build_output_path(permalink)
      File.join(permalink.sub(%r{^/}, ""), "index.html")
    end

    def build_url(permalink)
      return permalink if @site["base_url"].to_s.empty?

      "#{@site["base_url"]}#{permalink}"
    end

    def prettify_slug(slug)
      slug.to_s.tr("-", " ").split.map(&:capitalize).join(" ")
    end

    def render_markdown(content)
      builder = lambda do |language, code_body, executable|
        build_code_window(language, code_body, executable: executable)
      end

      Typophic::Renderer::Markdown
        .new(content, code_window_builder: builder)
        .render
    end

    def run_content_pipeline(page, body)
      steps = Typophic::Pipeline.content_steps
      content = steps.reduce(body) do |content, step_name|
        method = "pipeline_#{step_name}"
        respond_to?(method, true) ? send(method, content, page) : content
      end
      normalize_code_windows(content)
    end

    def pipeline_rubocop_ruby_blocks(content, page)
      return content unless defined?(Typophic::InlineRuboCop)

      formatter = Typophic::InlineRuboCop.instance

      # Process #> ruby blocks
      content = content.gsub(/^#>\s*ruby(?::\s*(.*))?\r?\n(.*?)^#!\s*$/m) do
        options_raw = Regexp.last_match(1).to_s
        code_body   = Regexp.last_match(2)

        tokens = options_raw.split
        if tokens.include?("format")
          formatted = formatter.format(code_body, file: page["source"] || "(ruby-block)")
          options_out = (tokens - ["format"]).join(" ")
          options_suffix = options_out.empty? ? "" : ": #{options_out}"
          "#> ruby#{options_suffix}\n#{formatted.rstrip}\n#!"
        else
          Regexp.last_match(0)
        end
      end

      # Process standard markdown ```ruby blocks
      # Match ```ruby followed by code and closing ```
      # Note: This must run BEFORE markdown processing to preserve newlines
      content = content.gsub(/^```ruby\s*\r?\n(.*?)\r?\n```\s*$/m) do |match|
        code_body = Regexp.last_match(1)
        
        # Preserve the code structure - only remove trailing whitespace, keep all newlines
        code_body = code_body.rstrip
        
        # Format with RuboCop (this preserves newlines)
        formatted = formatter.format(code_body, file: page["source"] || "(ruby-block)")
        
        # Remove frozen_string_literal comment if RuboCop added it
        formatted = formatted.gsub(/^# frozen_string_literal: true\s*\n?/, '')
        
        # Preserve all newlines - only strip trailing whitespace from the end
        formatted = formatted.rstrip
        
        # Ensure we have a newline after the opening ```ruby and before closing ```
        # This preserves the structure that markdown expects
        "```ruby\n#{formatted}\n```"
      end

      content
    rescue
      content
    end

    def pipeline_hash_blocks(content, _page)
      html = content.dup

      html.gsub!(/^#>\s*([A-Za-z0-9_+\-]+)(?::\s*(.*))?\r?\n(.*?)^#!\s*$/m) do
        lang          = Regexp.last_match(1)
        options_raw   = Regexp.last_match(2).to_s
        code_body_raw = Regexp.last_match(3)

        # Skip diagram blocks - they're handled by dedicated pipeline steps
        next Regexp.last_match(0) if %w[mermaid ditaa].include?(lang.downcase)

        code_body     = code_body_raw.strip
        tokens        = options_raw.split
        executable    = tokens.include?("run")

        build_code_window(lang, code_body, executable: executable)
      end

      html
    end

    def pipeline_mermaid_blocks(content, _page)
      html = content.dup

      html.gsub!(/^#>\s*mermaid(?::\s*(.*))?\r?\n(.*?)^#!\s*$/m) do
        options_raw = Regexp.last_match(1).to_s
        diagram_content = Regexp.last_match(2)

        # Parse options like caption="My Diagram" class="custom-class"
        options = parse_block_options(options_raw)

        Typophic::Renderer::Diagram.mermaid(diagram_content, options)
      end

      html
    end

    def pipeline_ditaa_blocks(content, _page)
      html = content.dup

      html.gsub!(/^#>\s*ditaa(?::\s*(.*))?\r?\n(.*?)^#!\s*$/m) do
        options_raw = Regexp.last_match(1).to_s
        diagram_content = Regexp.last_match(2)

        # Parse options like output=media/images/diagram.png caption="My Diagram"
        options = parse_block_options(options_raw)

        Typophic::Renderer::Diagram.ditaa(diagram_content, options)
      end

      html
    end

    def parse_block_options(options_string)
      options = {}
      return options if options_string.nil? || options_string.empty?

      # Split by spaces but respect quotes
      tokens = options_string.scan(/(\w+)=(?:"([^"]*)"|(\S+))/)

      tokens.each do |key, quoted_val, unquoted_val|
        options[key] = quoted_val || unquoted_val
      end

      options
    end

    # Wrap legacy inline Ruby <pre> blocks that were authored directly in
    # Markdown as executable code windows so they pick up the same UI and
    # overlay behaviour as ruby-exec fences.
    # IMPORTANT: Skip pre blocks that are already inside code-window divs or have practice attributes
    def pipeline_ruby_pre_blocks(content, _page)
      html = content.dup

      # Skip pre blocks that already have practice attributes or are inside code-window divs
      html.gsub!(%r{<pre\s+class="language-ruby"\s+data-executable="true"[^>]*>.*?</pre>}m) do |pre_block|
        # Skip if this pre block has practice attributes (it's already a practice block)
        next pre_block if pre_block.include?('data-practice')
        # Skip if this pre block is already inside a code-window div
        next pre_block if pre_block.include?('code-window')
        <<~HTML.chomp
          <div class="code-window">
            <div class="code-header">
              <span class="window-btn red"></span>
              <span class="window-btn yellow"></span>
              <span class="window-btn green"></span>
              <span class="window-title">ruby.rb</span>
              <div class="loading-indicator">
                <span class="loading-spinner"></span>
                <span class="loading-text">Loading RubyVM</span>
              </div>
            </div>
            <div class="code-content">
              <div class="code-editor">
                #{pre_block}
              </div>
            </div>
          </div>
        HTML
      end

      html
    end

    def pipeline_practice_blocks(content, page)
      html = content.dup
      
      # Match practice blocks: #> ruby :practice ... #!
      # Pattern matches from #> ruby :practice to #!
      practice_index = 0
      pattern = /(^|\n)#>\s*ruby\s*:practice\s*\r?\n([\s\S]*?)^#!\s*$/m
      
      html.gsub!(pattern) do
        prefix = Regexp.last_match(1).to_s
        inner_content = Regexp.last_match(2) || ""
        
        # Extract TODO/initial code (everything before ```solution)
        # This includes any markdown content like **Goal:** lines and TODO comments
        todo_match = inner_content.match(/^([\s\S]*?)(?=```solution)/m)
        todo_content = todo_match ? todo_match[1] : ""
        
        # Filter out non-code lines (like **Goal:** markdown) - keep only lines that look like code/TODO comments
        # Keep lines that start with # (comments) or are blank, remove markdown formatting lines
        todo_lines = todo_content.lines.select do |line|
          stripped = line.strip
          stripped.empty? || stripped.start_with?("#") || !stripped.match(/^\*\*/)
        end
        todo_code = todo_lines.join("").strip
        
        # Extract solution code block
        solution_match = inner_content.match(/```solution\s*\r?\n([\s\S]*?)```/m)
        solution_code = solution_match ? solution_match[1].strip : ""
        
        # Extract test code block
        test_match = inner_content.match(/```test\s*\r?\n([\s\S]*?)```/m)
        test_code = test_match ? test_match[1].strip : ""
        
        # Generate practice chapter identifier from page permalink
        permalink = page["permalink"] || ""
        practice_chapter = "rl:chapter:#{permalink.chomp('/')}"
        
        current_index = practice_index
        practice_index += 1
        
        # HTML escape the test code and todo code for attributes
        require 'cgi'
        escaped_test = CGI.escapeHTML(test_code)
        escaped_todo = CGI.escapeHTML(todo_code)
        
        # Build the HTML structure for practice block
        replacement = <<~HTML
          <pre class="language-ruby"
               data-executable="true"
               data-practice-chapter="#{practice_chapter}"
               data-practice-index="#{current_index}"
               data-test="#{escaped_test}"><code class="language-ruby">#{escaped_todo}</code></pre>
          <div class="practice-feedback"
               data-practice-chapter="#{practice_chapter}"
               data-practice-index="#{current_index}"></div>
          
          <script type="text/plain"
                  data-practice-solution="#{practice_chapter}:#{current_index}">
          #{solution_code}
          </script>
        HTML
        "#{prefix}#{replacement}"
      end
      
      html
    end

    def pipeline_ruby_exec(content, _page)
      html = content.dup

      html.gsub!(/```ruby-exec[ \t]*\r?\n(.*?)```/m) do
        code_content = Regexp.last_match(1).strip
        build_code_window('ruby', code_content, executable: true)
      end

      html
    end

    def pipeline_markdown(content, _page)
      render_markdown(content)
    end

    # Collapse nested code-window wrappers to avoid double windows.
    # Keeps the inner window (with the actual <pre> block).
    def normalize_code_windows(html)
      pattern = /
        <div\s+class="code-window">\s*
          <div\s+class="code-header">.*?<\/div>\s*
          <div\s+class="code-content">\s*
            <div\s+class="code-editor">\s*
              (?<inner><div\s+class="code-window">.*?<\/div>)\s*
            <\/div>\s*
          <\/div>\s*
        <\/div>
      /mx

      html.gsub(pattern) do |match|
        m = pattern.match(match)
        m && m[:inner] ? m[:inner] : match
      end
    end

    def build_code_window(language, code_body, executable: false)
      lang = (language && !language.empty?) ? language : nil
      window_title = lang ? "#{lang}.#{lang == 'ruby' ? 'rb' : lang}" : 'code'
      window_title = 'ruby.rb' if lang == 'ruby'
      code_classes = ["language-#{lang || 'code'}"]
      code_classes << 'ruby-exec' if executable
      pre_classes = ['code-editor__highlight']
      pre_classes << 'language-ruby' if lang == 'ruby'
      pre_attributes = []
      pre_attributes << %(class="#{pre_classes.join(' ')}")
      pre_attributes << 'data-executable="true"' if executable
      pre_attributes << 'style="white-space: pre-wrap; outline: none;"'
      pre_attr = pre_attributes.any? ? ' ' + pre_attributes.join(' ') : ''
      code_attributes = ["class=\"#{code_classes.join(' ')}\""]
      code_attr = code_attributes.join(' ')
      escaped_code = ERB::Util.html_escape(code_body)

      <<~HTML.chomp
        <div class="code-window">
          <div class="code-header">
            <span class="window-btn red"></span>
            <span class="window-btn yellow"></span>
            <span class="window-btn green"></span>
            <span class="window-title">#{window_title}</span>
            <div class="loading-indicator">
              <span class="loading-spinner"></span>
              <span class="loading-text">Loading RubyVM</span>
            </div>
          </div>
          <div class="code-content">
            <div class="code-editor">
              <pre#{pre_attr}><code #{code_attr}>#{escaped_code}
              </code></pre>
            </div>
          </div>
        </div>
      HTML
    end

    def render_layout(layout_name, content, page_data, theme_name)
      layout_path = find_layout_path(layout_name, theme_name)
      raise "Missing layout: #{layout_name}" unless layout_path

      front_matter, template_body = extract_front_matter(File.read(layout_path))

      layout_theme_path = theme_path_for_layout(layout_path)
      includes_dir = layout_theme_path ? File.join(layout_theme_path, "includes") : nil

      # Check if it's a Liquid layout
      if layout_path.end_with?(".liquid") || layout_path.end_with?(".html") # Assume .html in layouts might be Liquid if they contain {{ }}
         # Simple heuristic: if it has Liquid tags, treat as Liquid.
         # Or better: if the file extension is .liquid OR if we are in a theme that uses Liquid.
         # Since we are standardizing on Liquid for themes, we should try Liquid first or fallback.
         # However, for now, let's look at the extension or content.
         # The rubylearning theme uses .html for layouts but they are Liquid.
         # So we should treat .html layouts as Liquid if they don't look like ERB.
         is_liquid = layout_path.end_with?(".liquid") || !template_body.include?("<%")

         if is_liquid
           renderer = Typophic::Renderer::Liquid.new(
             site: @site,
             page: page_data,
             content: content,
             site_includes_dir: @site_includes_dir,
             theme_includes_dir: includes_dir,
             helpers: @helper_modules,
             current_theme: theme_name,
             builder: self
           )
           rendered = renderer.render(template_body)
         else
           # ERB fallback
           context = TemplateContext.new(
             site: @site,
             page: page_data,
             content: content,
             site_includes_dir: @site_includes_dir,
             theme_includes_dir: includes_dir,
             helpers: @helper_modules,
             current_theme: theme_name
           )
           rendered = context.render(template_body)
         end
         
         # Handle layout inheritance
         if front_matter["layout"] && !front_matter["layout"].empty?
           return render_layout(front_matter["layout"], rendered, page_data, theme_name)
         end
         
         rendered
      else
        # ERB
        context = TemplateContext.new(
          site: @site,
          page: page_data,
          content: content,
          site_includes_dir: @site_includes_dir,
          theme_includes_dir: includes_dir,
          helpers: @helper_modules,
          current_theme: theme_name
        )
        rendered = context.render(template_body)
      end

      parent_layout = front_matter.fetch("layout", nil)
      parent_layout ? render_layout(parent_layout, rendered, page_data, theme_name) : rendered
    end

    def render_inline_template(template_body, page_data, theme_name)
      theme_path = @theme_paths[theme_name]
      includes_dir = File.join(theme_path, "includes")

      # Heuristic for Liquid vs ERB
      if template_body.include?("{{") || template_body.include?("{%")
        renderer = Typophic::Renderer::Liquid.new(
          site: @site,
          page: page_data,
          content: "",
          site_includes_dir: @site_includes_dir,
          theme_includes_dir: includes_dir,
          helpers: @helper_modules,
          current_theme: theme_name,
          builder: self
        )
        renderer.render(template_body)
      else
        context = TemplateContext.new(
          site: @site,
          page: page_data,
          content: "",
          site_includes_dir: @site_includes_dir,
          theme_includes_dir: includes_dir,
          helpers: @helper_modules,
          current_theme: theme_name
        )
        context.render(template_body)
      end
    end


    # Insert missing newlines between Ruby tokens that often get jammed
    # during content edits or Markdown conversions.
    def normalize_ruby_code(code)
      starters = %w[class module def begin rescue ensure else elsif when end puts print p pp attr_reader attr_writer attr_accessor require include extend case unless if do while until for]

      # Split glued tokens that frequently appear when Markdown editing strips
      # newlines (e.g., "endclass", "}.each").
      glue_fixed = code
      glue_fixed = glue_fixed.gsub(/([)\}\]])(?=[A-Za-z_])/, "\\1\n")
      glue_fixed = glue_fixed.gsub(/end(?=\S)/, "end\n")
      glue_fixed = glue_fixed.gsub(/\.new(?=[A-Za-z_])/, ".new\n")
      glue_fixed = glue_fixed.gsub(/((?:\"[^\"]*\")|(?:'[^']*'))(?=[A-Za-z_])/, "\\1\n")
      glue_fixed = glue_fixed.gsub(/(\d)(?=puts\b)/, "\\1\n")

      lines = glue_fixed.split("\n")
      indent_level = 0
      formatted = []

      lines.each do |line|
        raw = line.rstrip
        stripped = raw.strip

        if stripped.empty?
          formatted << ""
          next
        end

        lower = stripped.split('#').first&.strip
        if lower
          if lower =~ /^(end)\b/
            indent_level = [indent_level - 1, 0].max
          elsif lower =~ /^(elsif|else|when|ensure|rescue)\b/
            indent_level = [indent_level - 1, 0].max
          end
        end

        formatted << ('  ' * indent_level) + stripped

        if lower
          if lower =~ /^(class|module|def|case|begin|while|until|for|loop|unless|if|do)\b/ || stripped =~ /do\b(?!.*end)/
            indent_level += 1
          elsif lower =~ /^(elsif|else|when|ensure|rescue)\b/
            indent_level += 1
          end
        end
      end

      formatted.join("\n").gsub(/\n{3,}/, "\n\n")
    end

    def find_layout_path(layout_name, theme_name)
      candidates = []

      if @site_layouts_dir && File.directory?(@site_layouts_dir)
        candidates << File.join(@site_layouts_dir, "#{layout_name}.html")
        candidates << File.join(@site_layouts_dir, "#{layout_name}.liquid")
      end

      # Primary: current page/theme
      theme_path = @theme_paths[theme_name]
      if theme_path
        candidates << File.join(theme_path, "layouts", "#{layout_name}.html")
        candidates << File.join(theme_path, "layouts", "#{layout_name}.liquid")
      end

      # Secondary: known good fallback theme(s)
      if @theme_paths["rubylearning"]
        candidates << File.join(@theme_paths["rubylearning"], "layouts", "#{layout_name}.html")
        candidates << File.join(@theme_paths["rubylearning"], "layouts", "#{layout_name}.liquid")
      end

      # Tertiary: any other theme we know about
      @theme_paths.each do |name, path|
        next if name == theme_name || name == "rubylearning"
        candidates << File.join(path, "layouts", "#{layout_name}.html")
        candidates << File.join(path, "layouts", "#{layout_name}.liquid")
      end

      # Legacy default
      candidates << File.join(@theme_path, "layouts", "#{layout_name}.html")
      candidates << File.join(@theme_path, "layouts", "#{layout_name}.liquid")

      candidates.find { |path| File.exist?(path) }
    end

    def theme_path_for_layout(layout_path)
      abs = File.expand_path(layout_path)
      @theme_paths.each_value do |path|
        base = File.expand_path(File.join(path, "layouts"))
        return path if abs.start_with?(base)
      end
      nil
    end

    def index_page(page)
      section = page["section"]
      return if section.nil? || section.empty?

      @collections[section] << page

      return unless section == "posts"

      if (date = page["date"]) && date.respond_to?(:year)
        @archives[date.year] << page
      end

      Array(page["tags"]).each do |tag|
        @taxonomies[:tags][tag] << page
      end
    end

    def write_collection_indexes
      return if @collections.empty?

      data_dir = File.join(@output_dir, "typophic")
      FileUtils.mkdir_p(data_dir)

      @collections.each do |section, pages|
        summaries = pages.map do |page|
          {
            "title" => page["title"],
            "description" => page["description"],
            "permalink" => page["permalink"],
            "url" => page["url"],
            "date" => serialize_date(page["date"]),
            "tags" => Array(page["tags"]).map(&:to_s)
          }
        end

        File.write(
          File.join(data_dir, "#{section}.json"),
          JSON.pretty_generate(summaries)
        )
      end

      inject_collection_data_into_site
    end

    def inject_collection_data_into_site
      archive_entries = @archives.keys.sort.reverse.map do |year|
        {
          "year" => year,
          "posts" => @archives[year].sort_by { |p| p["date"] || Date.today }.reverse
        }
      end

      tag_entries = @taxonomies[:tags].keys.sort.map do |tag|
        {
          "name" => tag,
          "posts" => @taxonomies[:tags][tag].sort_by { |p| p["date"] || Date.today }.reverse
        }
      end

      @site["archives"] = archive_entries
      @site["tags"] = tag_entries
      @site["collections"] = @collections
    end

    def stringify_keys(hash)
      hash.each_with_object({}) do |(key, value), memo|
        memo[key.to_s] = value
      end
    end

    def parse_date(value)
      case value
      when Date
        value
      when Time
        value.to_date
      when String
        Date.parse(value)
      else
        nil
      end
    rescue ArgumentError
      nil
    end

    def serialize_date(value)
      return value.strftime("%Y-%m-%d") if value.respond_to?(:strftime)

      value
    end

    class TemplateContext
      attr_reader :site, :page

      def initialize(site:, page:, content:, site_includes_dir:, theme_includes_dir:, helpers: [], current_theme: nil)
        @site_hash = site
        @page_hash = page
        @content = content
        @site_includes_dir = site_includes_dir
        @theme_includes_dir = theme_includes_dir
        @helper_modules = Array(helpers)
        @current_theme = current_theme

        @helper_modules.each do |mod|
          singleton_class.include(mod)
        end

        @site = deep_struct(site)
        @page = deep_struct(page)
      end

      # Helper method to filter collections like Hugo's where function
      def where(collection, field, value)
        return [] unless collection.is_a?(Array)
        
        collection.select do |item|
          if field.include?('.')
            # Handle nested field access like "Params.featured"
            nested_value = get_nested_value(item, field)
            nested_value == value
          else
            item.is_a?(Hash) ? item[field] == value : (item.respond_to?(field) ? item.send(field) == value : false)
          end
        end
      end

      # Helper method to filter by type like .Site.RegularPages "Type" "services"
      def where_type(pages_collection, type_value)
        # Filter pages by type field (similar to Hugo's .Type)
        pages_collection.select { |page| page.is_a?(Hash) && page["type"] == type_value }
      end

      # Helper method to get nested values for field access like .Params.featured
      def get_nested_value(item, field_path)
        parts = field_path.split('.')
        current = item

        parts.each do |part|
          if current.is_a?(Hash)
            current = current[part]
          elsif current.respond_to?(:to_h)
            hash_val = current.to_h
            current = hash_val[part]
          else
            return nil
          end
          break if current.nil?
        end

        current
      end

      # Helper method to sort collections
      def sort_by_field(collection, field_path)
        return [] unless collection.is_a?(Array)
        
        collection.sort_by do |item|
          if field_path.include?('.')
            get_nested_value(item, field_path) || 0
          else
            item.is_a?(Hash) ? item[field_path] || 0 : (item.respond_to?(field_path.to_sym) ? item.send(field_path.to_sym) : 0)
          end
        end
      end

      # Helper method to take first N items
      def take_first(collection, n)
        return [] unless collection.is_a?(Array)
        collection.first(n.to_i)
      end

      def render(template)
        ERB.new(template, trim_mode: "-").result(binding)
      end

      def content
        @content
      end

      def asset_path(relative_path)
        relative = relative_path.to_s.sub(%r{^/}, "")
        combine_with_base(relative)
      end

      def theme_asset_path(relative_path, theme_name = nil)
        name = (theme_name || @current_theme).to_s
        relative = relative_path.to_s.sub(%r{^/}, "")
        combine_with_base(File.join("themes", name, relative))
      end

      def url_for(relative_path)
        relative = relative_path.to_s
        relative = relative == "/" ? "/" : relative.sub(%r{^/}, "")
        combine_with_base(relative)
      end

      def truncate(text, length: 100, omission: "…")
        return "" if text.nil?

        stripped = text.to_s
        return stripped if stripped.length <= length

        stripped[0, length].rstrip + omission
      end

      def strip_html(text)
        return "" if text.nil?

        text.to_s.gsub(/<[^>]*>/, "")
      end

      def absolute_url(relative_path)
        return url_for(relative_path) if @site_hash["base_url"].to_s.empty?

        relative = relative_path.to_s
        relative = relative.start_with?("/") ? relative : "/#{relative}"
        "#{@site_hash["base_url"]}#{relative}"
      end

      def base_path
        @site_hash["base_path"] || ""
      end

      def render_partial(name, locals = {})
        path = partial_path(name)
        raise "Missing partial: #{name}" unless path

        partial_context = TemplateContext.new(
          site: @site_hash,
          page: @page_hash.merge(stringify_keys(locals)),
          content: "",
          site_includes_dir: @site_includes_dir,
          theme_includes_dir: @theme_includes_dir,
          helpers: @helper_modules
        )

        ERB.new(File.read(path), trim_mode: "-").result(partial_context.send(:binding))
      end

      def partial?(name)
        !partial_path(name).nil?
      end

      private

      def deep_struct(value)
        case value
        when Hash
          OpenStruct.new(value.each_with_object({}) do |(k, v), memo|
            memo[k.to_sym] = deep_struct(v)
          end)
        when Array
          value.map { |item| deep_struct(item) }
        else
          value
        end
      end

      def stringify_keys(hash)
        hash.each_with_object({}) do |(key, value), memo|
          memo[key.to_s] = value
        end
      end

      def partial_path(name)
        candidates = []

        if @site_includes_dir && File.directory?(@site_includes_dir)
          candidates << File.join(@site_includes_dir, "#{name}.html")
          candidates << File.join(@site_includes_dir, "_#{name}.html")
        end

        if @theme_includes_dir && File.directory?(@theme_includes_dir)
          candidates << File.join(@theme_includes_dir, "#{name}.html")
          candidates << File.join(@theme_includes_dir, "_#{name}.html")
        end

        candidates.find { |path| File.exist?(path) }
      end

      def combine_with_base(relative)
        clean_relative = relative.to_s
        return base_path.empty? ? "/" : "#{base_path}/" if clean_relative.empty? || clean_relative == "/"

        clean_relative = clean_relative.sub(%r{^/}, "")
        path = base_path.empty? ? "/#{clean_relative}" : "#{base_path}/#{clean_relative}"
        path.gsub(%r{//+}, "/")
      end
    end
  end

end
