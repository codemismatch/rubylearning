# frozen_string_literal: true

require "fileutils"
require "yaml"
require "date"
require "time"
require "json"
require "erb"
require "uri"
require "ostruct"
require "set"

require_relative "tutorial_formatter"

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
                :site_assets_dir

    SUPPORTED_CONTENT_EXTENSIONS = %w[.md .markdown .html .htm .erb].freeze

    def initialize(options = {})
      @source_dir   = options[:source_dir] || "content"
      @output_dir   = options[:output_dir] || "public"
      @theme_root   = options[:theme_root] || "themes"
      @data_dir     = options[:data_dir] || "data"
      @site_layouts_dir  = options[:layouts_dir]  || "layouts"
      @site_includes_dir = options[:includes_dir] || "includes"
      @site_assets_dir   = options[:assets_dir]   || "assets"

      @config = load_config

      configure_themes(options)

      @site       = build_site_context(@config)
      @collections = Hash.new { |hash, key| hash[key] = [] }
      @archives    = Hash.new { |hash, key| hash[key] = [] }
      @taxonomies  = { tags: Hash.new { |hash, key| hash[key] = [] } }
      @helper_modules = load_helpers
    end

    def build
      puts "Building site..."

      normalize_content_quotes

      FileUtils.rm_rf(Dir.glob(File.join(@output_dir, "*")))

      collect_content_theme_overrides
      copy_static_assets
      process_content_files
      write_collection_indexes

      puts "Site built successfully!"
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
              config = YAML.load_file("config.yml")
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
            content = YAML.safe_load(File.read(file), aliases: true)
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
      @theme_paths.each do |theme_name, path|
        %w[css js images].each do |asset_dir|
          destination = theme_asset_destination(theme_name, asset_dir)
          copy_asset_tree(File.join(path, asset_dir), destination, "theme: #{theme_name}")
        end
      end

      # Back-compat: also copy the default theme to root-level asset dirs
      %w[css js images].each do |asset_dir|
        copy_asset_tree(File.join(@theme_path, asset_dir), asset_dir, "default theme (root)")
      end

      %w[css js images].each do |asset_dir|
        copy_asset_tree(File.join(@site_assets_dir, asset_dir), asset_dir, "site")
      end
    end

    def copy_asset_tree(source, destination_dir, label)
      return unless Dir.exist?(source)

      destination = File.join(@output_dir, destination_dir)
      FileUtils.mkdir_p(destination)

      Dir.glob(File.join(source, "**", "*")) do |file|
        next if File.directory?(file)

        relative = file.delete_prefix("#{source}/")
        target = File.join(destination, relative)
        FileUtils.mkdir_p(File.dirname(target))
        FileUtils.cp(file, target)
        puts "Copied #{label} asset: #{file}"
      end
    end

    def process_content_files
      entries = Dir.glob(File.join(@source_dir, "**", "*"))
                   .select { |path| File.file?(path) && supported_content_file?(path) }
                   .sort
                   .map { |file| parse_page(file) }

      entries.each { |entry| index_page(entry[:meta]) }
      inject_collection_data_into_site

      entries.each { |entry| render_page(entry) }
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

      puts "Generated: #{output_path}"
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

      case File.extname(path).downcase
      when ".md", ".markdown"
        :markdown
      when ".html", ".htm"
        :html
      when ".erb"
        :erb
      else
        :markdown
      end
    end

    def strip_supported_extensions(filename)
      base = filename.dup
      base = base.sub(/\.html\.erb\z/i, "")
      base = base.sub(/\.(md|markdown|html|htm|erb)\z/i, "")
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
      if raw =~ /\A---\n(.+?)\n---\n(.*)/m
        data = YAML.safe_load(
          Regexp.last_match(1),
          permitted_classes: [Date, Time],
          aliases: true
        ) || {}
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
      page["type"] = content_type  # Add Hugo-like content type
      page["source"] = relative_source
      page["slug"] = slug
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
      html = content.dup
      # Handle code blocks BEFORE any other markdown transforms so that
      # content inside fenced blocks (like lines starting with '#') does not
      # get interpreted as headings or lists.
      html.gsub!(/```([a-z]*)[ \t]*\r?\n(.*?)```/m) do
        lang = Regexp.last_match(1)
        code_content = Regexp.last_match(2).gsub(/^\s+|\s+$/, '')
        language = lang.empty? ? nil : lang
        build_code_window(language, code_content, executable: (language == 'ruby'))
      end

      # Protect all <pre> and <script> blocks from further markdown transforms
      pre_blocks = []
      html.gsub!(%r{<pre[^>]*>.*?</pre>}m) do |block|
        token = "\x00PRE_#{pre_blocks.length}\x00"
        pre_blocks << block
        token
      end
      
      script_blocks = []
      html.gsub!(%r{<script[^>]*>.*?</script>}m) do |block|
        token = "\x00SCRIPT_#{script_blocks.length}\x00"
        script_blocks << block
        token
      end

      # Now apply the rest of the lightweight markdown transforms
      # (headings, inline code, links, lists, etc.) safely
      html.gsub!(/^(#+)\s+(.+)$/) do
        level = Regexp.last_match(1).length
        heading_text = Regexp.last_match(2)
        slug = nil

        if heading_text =~ /\s*\{#([^}]+)\}\s*$/
          slug = Regexp.last_match(1)
          heading_text = heading_text.sub(/\s*\{#([^}]+)\}\s*$/, "")
        end

        heading_text = heading_text.strip

        if slug
          "<h#{level} id=\"#{slug}\">#{heading_text}</h#{level}>"
        else
          "<h#{level}>#{heading_text}</h#{level}>"
        end
      end

      html = "<p>" + html + "</p>"
      html.gsub!(/<\/p>\s*\n+\s*<p>/, "</p>\n<p>")
      html.gsub!(/<p>(<\/?(?:h[1-6]|pre|ul|ol|li|div|p)[^>]*>)<\/p>/m, "\\1")
      html.gsub!(/<p>\s*(<\/(?:h[1-6]|pre|ul|ol|li|div|p)>)\s*<\/p>/m, "\\1")
      html.gsub!(/`([^`]+)`/) do
        code_content = Regexp.last_match(1).gsub("<", "&lt;").gsub(">", "&gt;")
        "<code>#{code_content}</code>"
      end
      html.gsub!(/\[([^\]]+)\]\(([^\)]+)\)/, '<a href="\2">\1</a>')
      # Lists: convert only pure list lines outside of code blocks
      html.gsub!(/^\-\s+(.+)$/) { "<li>#{$1}</li>" }
      # Wrap consecutive <li> groups with <ul>
      html.gsub!(%r{(?:\A|\n)(<li>.+?</li>)(?=\n|\z)}m) { "<ul>#{$1}</ul>" }

      # Restore protected <pre> blocks
      pre_blocks.each_with_index do |block, i|
        html.gsub!("\x00PRE_#{i}\x00", block)
      end
      
      # Restore protected <script> blocks
      script_blocks.each_with_index do |block, i|
        html.gsub!("\x00SCRIPT_#{i}\x00", block)
      end

      "<div class='markdown'>#{html}</div>"
    end

    def run_content_pipeline(page, body)
      steps = Typophic::Pipeline.content_steps
      steps.reduce(body) do |content, step_name|
        method = "pipeline_#{step_name}"
        respond_to?(method, true) ? send(method, content, page) : content
      end
    end

    def pipeline_rubocop_ruby_blocks(content, page)
      return content unless defined?(Typophic::InlineRuboCop)

      formatter = Typophic::InlineRuboCop.instance

      content.gsub(/^#>\s*ruby(?::\s*(.*))?\r?\n(.*?)^#!\s*$/m) do
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
    rescue
      content
    end

    def pipeline_hash_blocks(content, _page)
      html = content.dup

      html.gsub!(/^#>\s*([A-Za-z0-9_+\-]+)(?::\s*(.*))?\r?\n(.*?)^#!\s*$/m) do
        lang          = Regexp.last_match(1)
        options_raw   = Regexp.last_match(2).to_s
        code_body_raw = Regexp.last_match(3)

        code_body     = code_body_raw.strip
        tokens        = options_raw.split
        executable    = tokens.include?("run")

        build_code_window(lang, code_body, executable: executable)
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

    def build_code_window(language, code_body, executable: false)
      lang = (language && !language.empty?) ? language : nil
      window_title = lang ? "#{lang}.#{lang == 'ruby' ? 'rb' : lang}" : 'code'
      window_title = 'ruby.rb' if lang == 'ruby'
      code_classes = ["language-#{lang || 'code'}"]
      code_classes << 'ruby-exec' if executable
      pre_attributes = []
      pre_attributes << 'class="language-ruby"' if lang == 'ruby'
      pre_attributes << 'data-executable="true"' if executable
      pre_attributes << 'contenteditable="true"' if executable
      pre_attributes << 'style="white-space: pre-wrap; outline: none;"'
      pre_attr = pre_attributes.any? ? ' ' + pre_attributes.join(' ') : ''
      escaped_code = ERB::Util.html_escape(code_body)

      <<~HTML.chomp
        <div class="code-window">
          <div class="code-header">
            <span class="window-btn red"></span>
            <span class="window-btn yellow"></span>
            <span class="window-btn green"></span>
            <span class="window-title">#{window_title}</span>
          </div>
          <div class="code-content">
            <pre#{pre_attr}><code class="#{code_classes.join(' ')}">#{escaped_code}
            </code></pre>
          </div>
        </div>
      HTML
    end

    def render_layout(layout_name, content, page_data, theme_name)
      layout_path = find_layout_path(layout_name, theme_name)
      raise "Missing layout: #{layout_name}" unless layout_path

      front_matter, template_body = extract_front_matter(File.read(layout_path))

      layout_theme_path = theme_path_for_layout(layout_path)

      context = TemplateContext.new(
        site: @site,
        page: page_data,
        content: content,
        site_includes_dir: @site_includes_dir,
        theme_includes_dir: layout_theme_path ? File.join(layout_theme_path, "includes") : nil,
        helpers: @helper_modules,
        current_theme: theme_name
      )

      rendered = context.render(template_body)

      parent_layout = front_matter.fetch("layout", nil)
      parent_layout ? render_layout(parent_layout, rendered, page_data, theme_name) : rendered
    end

    def render_inline_template(template_body, page_data, theme_name)
      theme_path = @theme_paths[theme_name]
      context = TemplateContext.new(
        site: @site,
        page: page_data,
        content: "",
        site_includes_dir: @site_includes_dir,
        theme_includes_dir: File.join(theme_path, "includes"),
        helpers: @helper_modules,
        current_theme: theme_name
      )

      context.render(template_body)
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
      end

      # Primary: current page/theme
      theme_path = @theme_paths[theme_name]
      candidates << File.join(theme_path, "layouts", "#{layout_name}.html") if theme_path

      # Secondary: known good fallback theme(s)
      if @theme_paths["rubylearning"]
        candidates << File.join(@theme_paths["rubylearning"], "layouts", "#{layout_name}.html")
      end

      # Tertiary: any other theme we know about
      @theme_paths.each do |name, path|
        next if name == theme_name || name == "rubylearning"
        candidates << File.join(path, "layouts", "#{layout_name}.html")
      end

      # Legacy default
      candidates << File.join(@theme_path, "layouts", "#{layout_name}.html")

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
