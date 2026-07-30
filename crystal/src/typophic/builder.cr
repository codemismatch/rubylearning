# frozen_string_literal: true

require "file_utils"
require "yaml"
require "json"
require "time"
require "uri"
require "http/client"
require "digest/md5"
require "html"
require "liquid"
require "log"
require "wait_group"
require "channel"
require "./util"
require "./pipeline"
require "./filters"

module Typophic
  # Core static-site builder that transforms Markdown content and ERB templates
  # into a fully-linked static site.
  class Builder
    property source_dir : String
    property output_dir : String
    property theme_root : String
    property data_dir : String
    property site_layouts_dir : String
    property site_includes_dir : String
    property site_assets_dir : String
    property parallel : Bool
    property thread_count : Int32
    property verbose : Bool

    # Placeholders for now
    property config : Hash(String, YAML::Any)
    property site : Hash(String, YAML::Any) # Back to Hash
    property collections : Hash(String, Array(Hash(String, YAML::Any)))
    property archives : Hash(Int32, Array(Hash(String, YAML::Any)))
    property taxonomies : Hash(String, Hash(String, Array(Hash(String, YAML::Any))))
    property helper_modules : Array(String)
    property default_theme_name : String = ""
    property section_theme_map : Hash(String, String) = Hash(String, String).new
    property theme_name : String = ""
    property theme_path : String = ""
    property theme_paths : Hash(String, String) = Hash(String, String).new
    property include_dir_cache : Hash(String, String) = Hash(String, String).new

    SUPPORTED_CONTENT_EXTENSIONS = %w[.md .markdown .html .htm .erb]

    def initialize(options : Hash(String, String))
      @source_dir   = options["source_dir"]? || "content"
      @output_dir   = options["output_dir"]? || "public"
      @theme_root   = options["theme_root"]? || "themes"
      @data_dir     = options["data_dir"]? || "data"
      @site_layouts_dir  = options["layouts_dir"]?  || "layouts"
      @site_includes_dir = options["includes_dir"]? || "includes"
      @site_assets_dir   = options["assets_dir"]?   || "assets"
      @parallel     = options["parallel"]? ? options["parallel"]?.to_s == "true" : true
      @thread_count = (options["thread_count"]? || System.cpu_count).to_i
      @verbose      = options["verbose"]? ? options["verbose"]?.to_s == "true" : true
      Log.setup_from_env

      @config = load_config
      configure_themes(options)

      @site       = build_site_context(@config)
      @collections = Hash(String, Array(Hash(String, YAML::Any))).new { |h, k| h[k] = [] of Hash(String, YAML::Any) }
      @archives    = Hash(Int32, Array(Hash(String, YAML::Any))).new { |h, k| h[k] = [] of Hash(String, YAML::Any) }
      @taxonomies  = {"tags" => Hash(String, Array(Hash(String, YAML::Any))).new { |h, k| h[k] = [] of Hash(String, YAML::Any) }}
      @helper_modules = load_helpers

      base_path = @site["base_path"]?.try &.as_s?
      base_url = @site["base_url"]?.try &.as_s?
      Typophic::FilterConfig.configure(base_path, base_url, @default_theme_name)
    end

    def build
      start_time = Time.local
      Log.info { "Building site#{@parallel ? " (parallel: #{@thread_count} threads)" : " (sequential)"}..." }

      normalize_content_quotes

      # Clean output directory
      if Dir.exists?(@output_dir)
        Dir.glob(File.join(@output_dir, "*")).each do |path|
          FileUtils.rm_rf(path)
        end
      end

      collect_content_theme_overrides
      copy_static_assets
      process_content_files
      write_collection_indexes
      
      elapsed = Time.local - start_time
      Log.info { "Site built successfully! (#{elapsed.total_seconds.round(2)}s)" }
    end

    private def normalize_content_quotes
      content_root = @source_dir
      target_exts = %w[.md .markdown]
      smart_map = {
        '\u201C' => '"',
        '\u201D' => '"',
        '\u2018' => "'",
        '\u2019' => "'",
        '\u2013' => "-",
        '\u2014' => "-",
      }

      Dir.glob(File.join(content_root, "**", "*")).each do |path|
        next unless File.file?(path)
        ext = File.extname(path).downcase
        next unless target_exts.includes?(ext)

        begin
          original = File.read(path, encoding: "UTF-8")
          normalized = original.dup
          smart_map.each do |from, to|
            normalized = normalized.gsub(from, to)
          end

          if normalized != original
            File.write(path, normalized)
            Log.info { "Normalized quotes in: #{path}" } if @verbose
          end
        rescue ex : Exception
          Log.warn { "Skipping #{path} due to encoding error: #{ex.message}" }
        end
      end
    end

    private def collect_content_theme_overrides
      Dir.glob(File.join(@source_dir, "**", "*.{md,markdown,html,erb}")).each do |file|
        begin
          raw = File.read(file)
          front_matter, _ = extract_front_matter(raw)
          theme_any = front_matter["theme"]?
          if theme_any && (theme_str = theme_any.as_s?) && !theme_str.strip.empty?
            theme_path = File.join(@theme_root, theme_str)
            if Dir.exists?(theme_path)
              @theme_paths[theme_str] ||= theme_path
            end
          end
        rescue ex
          Log.warn { "Ignoring parse error in file for theme override: #{ex.message}" }
        end
      end
    end

    private def extract_front_matter(raw : String) : Tuple(Hash(String, YAML::Any), String)
      if match = raw.match(/\A---\n(.+?)\n---\n(.*)/m)
        front_matter_raw = match[1]?.to_s || ""
        body = match[2]?.to_s || ""
        begin
          data = Typophic::Util.yaml_hash_to_string_keys(YAML.parse(front_matter_raw).as_h)
          return {data, body}
        rescue ex
          Log.warn { "Failed to parse front matter: #{ex.message}" }
          return {Hash(String, YAML::Any).new, raw}
        end
      else
        return {Hash(String, YAML::Any).new, raw}
      end
    end

    private def copy_static_assets
      copy_tasks = Array(Tuple(String, String, String)).new

      @theme_paths.each do |theme_name, path|
        %w[css js images].each do |asset_dir|
          copy_tasks << {File.join(path, asset_dir), theme_asset_destination(theme_name, asset_dir), "theme: #{theme_name}"}
        end
      end

      # Back-compat: also copy the default theme to root-level asset dirs
      %w[css js images].each do |asset_dir|
        copy_tasks << {File.join(@theme_path, asset_dir), asset_dir, "default theme (root)"}
      end

      %w[css js images].each do |asset_dir|
        copy_tasks << {File.join(@site_assets_dir, asset_dir), asset_dir, "site"}
      end

      if @parallel && copy_tasks.size > 1
        copy_assets_parallel(copy_tasks)
      else
        copy_tasks.each { |source, dest, label| copy_asset_tree(source, dest, label) }
      end
    end

    private def copy_assets_parallel(copy_tasks)
      channel = Channel(Tuple(String, String, String)).new(copy_tasks.size)
      copy_tasks.each { |task| channel.send(task) }
      channel.close

      wg = WaitGroup.new
      @thread_count.to_i.times do
        wg.add
        spawn do
          begin
            while task = channel.receive?
              source, dest, label = task
              copy_asset_tree(source, dest, label)
            end
          ensure
            wg.done
          end
        end
      end
      wg.wait
    end

    private def copy_asset_tree(source, destination_dir, label)
      return unless Dir.exists?(source)

      destination = File.join(@output_dir, destination_dir)
      FileUtils.mkdir_p(destination)

      files = Dir.glob(File.join(source, "**", "*")).select { |f| File.file?(f) }
      return if files.empty?

      files.each do |file|
        source_escaped = Regex.escape(source)
        relative = file.sub(/^#{source_escaped}\//, "")
        target = File.join(destination, relative)
        FileUtils.mkdir_p(File.dirname(target))
        FileUtils.cp(file, target)
      end

      Log.info { "Copied #{files.size} #{label} asset(s)" } if @verbose
    end

    private def theme_asset_destination(theme_name, asset_dir)
      File.join("themes", theme_name, asset_dir)
    end

    private def configure_themes(options : Hash(String, String))
      config_theme = @config["theme"]?

      if config_theme && (theme_str = config_theme.as_s?)
        @default_theme_name = options["theme"]? || theme_str
        @section_theme_map = Hash(String, String).new
      elsif config_theme && (theme_hash = config_theme.as_h?)
        default_from_config = theme_hash["default"]?.try &.as_s
        @default_theme_name = options["theme"]? || default_from_config || "rubylearning"
        
        sections = theme_hash["sections"]?.try &.as_h?
        @section_theme_map = Hash(String, String).new
        if sections
          sections.each do |key, value|
            @section_theme_map[key.to_s] = value.to_s
          end
        end
      else
        @default_theme_name = options["theme"]? || "rubylearning"
        @section_theme_map = Hash(String, String).new
      end

      @theme_name = @default_theme_name
      @theme_path = File.join(@theme_root, @default_theme_name)

      names = Set(String).new
      names << @default_theme_name
      @section_theme_map.each_value { |n| names << n }
      
      rubylearning_theme_path = File.join(@theme_root, "rubylearning")
      names << "rubylearning" if Dir.exists?(rubylearning_theme_path)
      
      @theme_paths = Hash(String, String).new
      names.each do |n|
        @theme_paths[n] = File.join(@theme_root, n)
      end

      @theme_paths.each do |name, path|
        raise "Theme '#{name}' not found at #{path}" unless Dir.exists?(path)
      end
    end

    private def load_config
      parsed_yaml = begin
        File.open("config.yml") do |file|
          YAML.parse(file)
        end
      rescue ex : File::NotFoundError
        Log.warn { "config.yml not found: #{ex.message}. Using empty configuration." }
        return Hash(String, YAML::Any).new
      rescue ex : YAML::ParseException
        Log.error(exception: ex) { "Failed to parse config.yml: #{ex.message}. Using empty configuration." }
        return Hash(String, YAML::Any).new
      end

      # Ensure parsed_yaml is a Hash and convert its keys to String
      config_h = if parsed_yaml.as_h?
        new_hash = Hash(String, YAML::Any).new
        parsed_yaml.as_h.each do |k, v|
          new_hash[k.to_s] = v.as(YAML::Any)
        end
        new_hash
      else
        Log.warn { "config.yml is not a hash. Using empty configuration." }
        Hash(String, YAML::Any).new
      end

      override = ENV["TYPOPHIC_URL_OVERRIDE"]?
      if override && !override.to_s.strip.empty?
        config_h["url"] = YAML::Any.new(override)
      end

      config_h
    end

    private def build_site_context(config)
      base_url_any = config["url"]?
      base_url = base_url_any ? base_url_any.to_s.strip : ""
      base_url = base_url.chomp('/') unless base_url.empty?

      uri = begin
        base_url.empty? ? URI.parse("/") : URI.parse(base_url)
      rescue ex : URI::Error
        URI.parse("/")
      end

      base_path = uri.path.to_s
      base_path = "" if base_path == "/"

      data_files = load_data_files
      localize_author_avatars(data_files)

      # Create a new hash to ensure we have a mutable copy
      site_context = config.dup

      site_context["base_url"] = YAML::Any.new(base_url)
      site_context["base_path"] = YAML::Any.new(base_path)
      site_context["title"] = config["site_name"]? || config["title"]? || YAML::Any.new("Typophic Site")
      site_context["build_time"] = YAML::Any.new(Time.local.to_unix)
      site_context["build_year"] = YAML::Any.new(Time.local.year)
      # Convert data_files keys to YAML::Any for the top-level hash
      converted_data_files_hash = Hash(YAML::Any, YAML::Any).new
      data_files.each do |k, v|
        converted_data_files_hash[YAML::Any.new(k)] = v # v is already YAML::Any
      end
      site_context["data"] = YAML::Any.new(converted_data_files_hash)
      
      site_context
    end

    private def load_data_files
      data = Hash(String, YAML::Any).new
      return data unless Dir.exists?(@data_dir)

      Dir.glob(File.join(@data_dir, "**", "*.{yaml,yml,json}")).each do |file|
        ext = File.extname(file).downcase
        data_name = File.basename(file, ext)

        begin
          content = case ext
          when ".yaml", ".yml"
            YAML.parse(File.read(file))
          when ".json"
            json_to_yaml_any(JSON.parse(File.read(file))) # Convert JSON::Any to YAML::Any
          else
            next
          end
          data[data_name] = content
        rescue ex
          Log.warn { "Could not load data file #{file}: #{ex.message}\n#{ex.inspect}" }
        end
      end
      data
    end

    # Rewrites remote author avatar URLs (e.g. avatars.githubusercontent.com) to
    # locally cached copies under assets/images/avatars/. Each avatar is
    # downloaded once and reused on subsequent builds, so rendered pages never
    # hotlink GitHub URLs that some clients block.
    private def localize_author_avatars(data : Hash(String, YAML::Any))
      authors_any = data["authors"]?
      return unless authors_any
      authors = authors_any.as_h?
      return unless authors

      cache_dir = File.join(@site_assets_dir, "images", "avatars")

      authors.each do |id_any, author_any|
        author = author_any.as_h?
        next unless author
        avatar_any = author[YAML::Any.new("avatar")]?
        next unless avatar_any
        avatar = avatar_any.as_s?
        next unless avatar
        next unless avatar.starts_with?("http://") || avatar.starts_with?("https://")

        github = author[YAML::Any.new("github")]?.try(&.as_s?) || id_any.as_s
        slug = github.gsub(/[^a-zA-Z0-9_-]/, "")
        next if slug.empty?

        local_file = Dir.glob(File.join(cache_dir, "#{slug}.*")).first?
        local_file ||= download_avatar(avatar, cache_dir, slug)
        if local_file
          author[YAML::Any.new("avatar")] = YAML::Any.new("/images/avatars/#{File.basename(local_file)}")
        end
      end
    end

    private def download_avatar(url : String, cache_dir : String, slug : String) : String?
      Dir.mkdir_p(cache_dir)

      uri = URI.parse(url)
      3.times do
        response = HTTP::Client.get(uri)

        case response.status_code
        when 301, 302, 303, 307, 308
          location = response.headers["Location"]?
          return nil unless location
          uri = URI.parse(location)
        when 200
          content_type = response.headers["Content-Type"]?.to_s
          ext = case content_type
                when .includes?("jpeg") then ".jpg"
                when .includes?("gif")  then ".gif"
                when .includes?("webp") then ".webp"
                else                         ".png"
                end
          path = File.join(cache_dir, "#{slug}#{ext}")
          File.write(path, response.body)
          Log.info { "Cached avatar: #{url} -> #{path}" }
          return path
        else
          return nil
        end
      end
      nil
    rescue ex
      Log.warn { "Could not cache avatar #{url}: #{ex.message}" }
      nil
    end

    # Recursively converts a JSON::Any into a YAML::Any
    private def json_to_yaml_any(json_value : JSON::Any) : YAML::Any
      case json_value.raw
      when String then YAML::Any.new(json_value.as_s)
      when Int32, Int64, Int128 then YAML::Any.new(json_value.as_i)
      when Float32, Float64 then YAML::Any.new(json_value.as_f)
      when Bool then YAML::Any.new(json_value.as_bool)
      when Nil then YAML::Any.new(nil)
      when Hash
        new_hash = {} of YAML::Any => YAML::Any
        json_value.as_h.each do |k, v|
          new_hash[YAML::Any.new(k.to_s)] = json_to_yaml_any(v)
        end
        YAML::Any.new(new_hash)
      when Array
        new_array = json_value.as_a.map { |v| json_to_yaml_any(v) }
        YAML::Any.new(new_array)
      else
        YAML::Any.new(json_value.to_s)
      end
    end

    private def process_content_files
      files = Dir.glob(File.join(@source_dir, "**", "*"))
                 .select { |path| File.file?(path) && supported_content_file?(path) }
                 .sort

      if @parallel && files.size > 1
        process_content_files_parallel(files)
      else
        process_content_files_sequential(files)
      end
    end

    private def process_content_files_sequential(files)
      entries = files.map { |file| parse_page(file) }

      entries.each { |entry| index_page(entry.meta) }
      inject_collection_data_into_site

      entries.each { |entry| render_page(entry) }
    end

    private def process_content_files_parallel(files)
      # Phase 1: Parse all files in parallel
      entries = parse_files_parallel(files)

      # Phase 2: Index pages (must be sequential due to shared state)
      entries.each { |entry| index_page(entry.meta) }
      inject_collection_data_into_site

      # Phase 3: Render pages in parallel
      render_pages_parallel(entries)
    end

    private struct PageEntry
      property meta : Hash(String, YAML::Any)
      property body : String
      property renderer : Renderer

      def initialize(@meta, @body, @renderer)
      end
    end

    private enum Renderer
      Markdown
      Erb
      Html
    end

    def parse_files_parallel(files)
      channel = Channel(String?).new(files.size)
      files.each { |f| channel.send(f) }
      channel.close

      entries = [] of PageEntry
      mutex = Mutex.new
      wg = WaitGroup.new
      [@thread_count, files.size].min.times do
        wg.add
        spawn do
          begin
            while file = channel.receive?
              begin
                entry = parse_page(file)
                mutex.synchronize do
                  entries << entry
                end
              rescue ex
                Log.warn { "Failed to parse #{file}: #{ex.message}" }
              end
            end
          ensure
            wg.done
          end
        end
      end
      wg.wait
      entries
    end

    def render_pages_parallel(entries)
      channel = Channel(PageEntry?).new(entries.size)
      entries.each { |e| channel.send(e) }
      channel.close

      wg = WaitGroup.new
      [@thread_count, entries.size].min.times do
        wg.add
        spawn do
          begin
            while entry = channel.receive?
              render_page(entry)
            end
          ensure
            wg.done
          end
        end
      end
      wg.wait
    end

    private def supported_content_file?(path)
      return true if path.ends_with?(".html.erb")
      ext = File.extname(path).downcase
      SUPPORTED_CONTENT_EXTENSIONS.includes?(ext)
    end

    private def renderer_for(path)
      return Renderer::Erb if path.ends_with?(".html.erb")

      case File.extname(path).downcase
      when ".md", ".markdown"
        Renderer::Markdown
      when ".html", ".htm"
        Renderer::Html
      when ".erb"
        Renderer::Erb
      else
        Renderer::Markdown
      end
    end

    private def parse_page(file)
      raw = File.read(file)
      front_matter, body = extract_front_matter(raw)
      renderer = renderer_for(file)
      meta = build_page_context(file, front_matter)

      PageEntry.new(meta, body, renderer)
    end

    private def build_page_context(file : String, front_matter : Hash(String, YAML::Any))
      source_dir_escaped = Regex.escape(@source_dir)
      relative_source = file.sub(/^#{source_dir_escaped}\/?/, "")
      segments = relative_source.split(File::SEPARATOR)
      section = segments.first? || ""
      filename = segments.last? || "index.md"
      stem = strip_supported_extensions(filename)

      slug, inferred_date = derive_slug_and_date(stem, front_matter)
      layout_any = front_matter["layout"]?
      layout = (layout_any ? layout_any.to_s : nil) || default_layout_for(section)

      content_type_any = front_matter["type"]?
      content_type = (content_type_any ? content_type_any.to_s : nil) || section

      permalink_any = front_matter["permalink"]?
      permalink_str = permalink_any ? permalink_any.to_s : nil
      permalink = (permalink_str.nil? || permalink_str.empty?) ? default_permalink(section, segments[1..-2]?, slug, filename) : permalink_str
      permalink = normalize_permalink(permalink)

      page = front_matter.dup
      page["layout"] = YAML::Any.new(layout)
      page["section"] = YAML::Any.new(section)
      page["type"] = YAML::Any.new(content_type)
      page["source"] = YAML::Any.new(relative_source)
      page["slug"] = YAML::Any.new(slug)
      
      if inferred_date
        page["date"] = YAML::Any.new(inferred_date)
      end

      page["permalink"] = YAML::Any.new(permalink)
      page["url"] = YAML::Any.new(build_url(permalink))
      page["output_path"] = YAML::Any.new(build_output_path(permalink))

      title_any = page["title"]?
      page["title"] = title_any || YAML::Any.new(prettify_slug(slug))
      
      tags_any = page["tags"]?
      page["tags"] = if tags_any
                       if tags_any.as_a?
                         tags_any # It's already YAML::Any(Array(YAML::Any))
                       else
                         YAML::Any.new([tags_any]) # It's a single tag, wrap it in an array
                       end
                     else
                       YAML::Any.new([] of YAML::Any)
                     end

      # Normalize frontmatter `author` (display name or id) to a canonical
      # author id from data/authors.yml so templates can render avatars.
      if author_any = page["author"]?
        author_str = author_any.as_s?
        if author_str && !author_str.empty?
          if resolved = resolve_author_id(author_str)
            page["author"] = YAML::Any.new(resolved)
          end
        end
      end

      page
    end

    @authors_registry : Hash(YAML::Any, YAML::Any)? = nil

    private def authors_registry
      @authors_registry ||= begin
        path = File.join(@data_dir, "authors.yml")
        if File.exists?(path)
          YAML.parse(File.read(path)).as_h? || Hash(YAML::Any, YAML::Any).new
        else
          Hash(YAML::Any, YAML::Any).new
        end
      end
    end

    private def resolve_author_id(author : String) : String?
      downcased = author.downcase
      authors_registry.each do |id_any, data_any|
        id = id_any.as_s
        return id if id.downcase == downcased
        name = data_any.as_h?.try { |h| h[YAML::Any.new("name")]?.try(&.as_s?) }
        return id if name && name.downcase == downcased
      end
      nil
    end

    private def strip_supported_extensions(filename)
      base = filename.dup
      base = base.sub(/\.html\.erb\z/i, "")
      base.sub(/\.(md|markdown|html|htm|erb)\z/i, "")
    end

    private def derive_slug_and_date(stem, front_matter)
      if match = stem.match(/(\d{4}-\d{2}-\d{2})-(.+)/)
        inferred_slug = match[2]?
        date_from_slug = match[1]?
        date = parse_date(YAML::Any.new(date_from_slug)) if date_from_slug
        {inferred_slug || stem, date}
      else
        {stem, nil}
      end
    end

    private def default_layout_for(section)
      section == "posts" ? "post" : "page"
    end

    private def default_permalink(section, intermediate_segments, slug, filename)
      case section
      when "posts"
        "/posts/#{slug}/"
      when "pages"
        "/pages/#{slug}/"
      else
        segments = intermediate_segments || [] of String
        path_parts = segments + [slug]
        "/#{path_parts.join("/")}/"
      end
    end

    private def normalize_permalink(permalink)
      permalink = permalink.chomp('/')
      permalink = "/#{permalink}" unless permalink.starts_with?('/')
      permalink = "#{permalink}/" unless permalink.ends_with?('/')
      permalink
    end

    private def build_output_path(permalink)
      File.join(permalink.sub(%r{^/}, ""), "index.html")
    end

    private def build_url(permalink)
      base_url_any = @site["base_url"]?
      base_url = base_url_any ? base_url_any.as_s : ""
      return permalink if base_url.empty?
      "#{base_url}#{permalink}"
    end

    private def prettify_slug(slug)
      slug.to_s.gsub("-", " ").split.map(&.capitalize).join(" ")
    end

    private def parse_date(value : YAML::Any?)
      return nil unless value
      
      case val_raw = value.raw
      when Time
        val_raw
      when String
        begin
          Time.parse(val_raw, "%Y-%m-%d", Time::Location::UTC)
        rescue
          nil
        end
      else
        nil
      end
    end

    private def index_page(meta)
      section_any = meta["section"]?
      return unless section_any
      section = section_any.as_s
      return if section.empty?

      (@collections[section] ||= [] of Hash(String, YAML::Any)) << meta

      return unless section == "posts"

      date_any = meta["date"]?
      if date_any && date_any.raw.is_a?(Time)
        date = date_any.raw.as(Time)
        (@archives[date.year] ||= [] of Hash(String, YAML::Any)) << meta
      end

      tags_any = meta["tags"]?
      if tags_any && (tags_arr = tags_any.as_a?)
        tags_arr.each do |tag_any|
          if tag_str = tag_any.as_s?
            ((@taxonomies["tags"]? || Hash(String, Array(Hash(String, YAML::Any))).new)[tag_str] ||= [] of Hash(String, YAML::Any)) << meta
          end
        end
      end
    end

    private def inject_collection_data_into_site
      archive_entries = @archives.keys.sort.reverse.map do |year|
        posts = @archives[year].sort_by do |p|
          date_any = p["date"]?
          if date_any && date_any.raw.is_a?(Time)
            date_any.raw.as(Time)
          else
            Time.local
          end
        end.reverse
        posts_yaml = posts.map do |p|
          page_yaml = Hash(YAML::Any, YAML::Any).new
          p.each { |pk, pv| page_yaml[YAML::Any.new(pk)] = pv }
          YAML::Any.new(page_yaml)
        end
        {
          "year" => YAML::Any.new(year),
          "posts" => YAML::Any.new(posts_yaml)
        }
      end

      tags_hash = @taxonomies["tags"]? || Hash(String, Array(Hash(String, YAML::Any))).new
      tag_entries = tags_hash.keys.sort.map do |tag|
        posts = tags_hash[tag].sort_by do |p|
          date_any = p["date"]?
          if date_any && date_any.raw.is_a?(Time)
            date_any.raw.as(Time)
          else
            Time.local
          end
        end.reverse
        posts_yaml = posts.map do |p|
          page_yaml = Hash(YAML::Any, YAML::Any).new
          p.each { |pk, pv| page_yaml[YAML::Any.new(pk)] = pv }
          YAML::Any.new(page_yaml)
        end
        {
          "name" => YAML::Any.new(tag),
          "posts" => YAML::Any.new(posts_yaml)
        }
      end

      # Convert archive_entries to YAML::Any format
      archives_yaml = archive_entries.map do |entry|
        entry_yaml = Hash(YAML::Any, YAML::Any).new
        entry.each do |k, v|
          entry_yaml[YAML::Any.new(k)] = v
        end
        YAML::Any.new(entry_yaml)
      end
      @site["archives"] = YAML::Any.new(archives_yaml)
      
      # Convert tag_entries to YAML::Any format
      tags_yaml = tag_entries.map do |entry|
        entry_yaml = Hash(YAML::Any, YAML::Any).new
        entry.each do |k, v|
          entry_yaml[YAML::Any.new(k)] = v
        end
        YAML::Any.new(entry_yaml)
      end
      @site["tags"] = YAML::Any.new(tags_yaml)
      
      # Convert collections to YAML::Any format
      collections_yaml = Hash(YAML::Any, YAML::Any).new
      @collections.each do |k, v|
        pages_yaml = v.map do |p|
          page_yaml = Hash(YAML::Any, YAML::Any).new
          p.each { |pk, pv| page_yaml[YAML::Any.new(pk)] = pv }
          YAML::Any.new(page_yaml)
        end
        collections_yaml[YAML::Any.new(k)] = YAML::Any.new(pages_yaml)
      end
      @site["collections"] = YAML::Any.new(collections_yaml)
    end

    private def render_page(entry)
      page = entry.meta
      theme_name = theme_for_page(page)
      page["theme"] = YAML::Any.new(theme_name)
      
      html_content = case entry.renderer
                     when Renderer::Markdown
                       run_content_pipeline(page, entry.body)
                     when Renderer::Erb
                       render_inline_template(entry.body, page, theme_name)
                     when Renderer::Html
                       entry.body
                     else
                       entry.body
                     end

      layout_name = page["layout"]?.try(&.as_s) || ""
      rendered = render_layout(layout_name, html_content, page, theme_name)

      output_path_any = page["output_path"]?
      return unless output_path_any
      output_path = File.join(@output_dir, output_path_any.as_s)
      FileUtils.mkdir_p(File.dirname(output_path))
      File.write(output_path, rendered)

      Log.info { "Generated: #{output_path}" } if @verbose
    end

    private def theme_for_page(page)
      theme_any = page["theme"]?
      theme_str = theme_any ? (theme_any.as_s? || theme_any.to_s) : ""
      return theme_str unless theme_str.strip.empty?
      section_any = page["section"]?
      section = section_any ? section_any.as_s : ""
      @section_theme_map[section]? || @default_theme_name
    end

    private def run_content_pipeline(page, body)
      content = body

      Typophic::Pipeline.content_steps.each do |step_name|
        case step_name
        when "rubocop_ruby_blocks"
          content = pipeline_rubocop_ruby_blocks(content, page)
        when "hash_blocks"
          content = pipeline_hash_blocks(content, page)
        when "practice_blocks"
          # Preserve Crystal's richer #> ruby :practice ... #! handling
          content = pipeline_practice_blocks(content, page)
        when "ruby_pre_blocks"
          content = pipeline_ruby_pre_blocks(content, page)
        when "ruby_exec"
          content = pipeline_ruby_exec(content, page)
        when "markdown"
          content = pipeline_markdown(content, page)
        when "mermaid_blocks"
          content = pipeline_mermaid_blocks(content, page)
        when "ditaa_blocks"
          # ditaa requires a local ditaa binary; only the Ruby engine runs it.
          content
        else
          # Unknown step name – ignore for forward compatibility
        end
      end

      normalize_code_windows(content)
    end

    private def pipeline_rubocop_ruby_blocks(content, page)
      # Not porting RuboCop integration; just return content
      content
    end

    # Transforms `#> mermaid: caption="..." ... #!` blocks into the same
    # diagram-container markup the Ruby engine produces (see
    # lib/typophic/renderer/diagram.rb).
    private def pipeline_mermaid_blocks(content : String, _page) : String
      regex = /^#>\s*mermaid(?::\s*([^\n]*))?\r?\n(.*?)^#!\s*$/m
      String.build do |io|
        pos = 0
        while match = regex.match(content, pos)
          io << content.byte_slice(pos, match.begin(0) - pos)
          options_raw = match[1]? || ""
          diagram = match[2]
          io << mermaid_html(diagram, parse_block_options(options_raw))
          pos = match.end(0)
        end
        io << content.byte_slice(pos)
      end
    end

    private def mermaid_html(diagram_content : String, options : Hash(String, String)) : String
      caption = options["caption"]? || ""
      css_class = options["class"]? || "mermaid-diagram"
      diagram_id = "mermaid-#{Digest::MD5.hexdigest(diagram_content)[0..7]}"

      html = [] of String
      html << %(<div class="diagram-container #{css_class}">)
      html << %(<div class="mermaid" id="#{diagram_id}">)
      html << diagram_content.strip
      html << %(</div>)
      html << %(<p class="diagram-caption">#{caption}</p>) unless caption.empty?
      html << %(</div>)
      html.join("\n")
    end

    private def parse_block_options(options_string : String?) : Hash(String, String)
      options = Hash(String, String).new
      return options if options_string.nil? || options_string.empty?

      options_string.scan(/(\w+)=(?:"([^"]*)"|(\S+))/) do |match|
        key = match[1]
        value = match[2]? || match[3]? || ""
        options[key] = value
      end

      options
    end

    private def pipeline_hash_blocks(content, page)
      lines = content.split(/\r?\n/)
      output = [] of String
      i = 0

      while i < lines.size
        line = lines[i]
        # Skip practice blocks - they're handled by pipeline_practice_blocks
        if m = /^#>\s*ruby\s*:practice/.match(line)
          # This is a practice block, don't process it here
          output << line
          i += 1
        elsif m = /^#>\s*([A-Za-z0-9_+\-]+)(?::\s*(.*))?\s*$/.match(line)
          lang = m[1]? ? m[1].to_s : ""
          options_raw = m[2]? ? m[2].to_s : ""

          # mermaid/ditaa blocks are handled by their own pipeline steps
          if %w[mermaid ditaa].includes?(lang.downcase)
            output << line
            i += 1
            next
          end

          i += 1
          code_lines = [] of String
          while i < lines.size && !(lines[i] =~ /^#!\s*$/)
            code_lines << lines[i]
            i += 1
          end
          # Skip the closing #! line if present
          i += 1 if i < lines.size && lines[i - 1] =~ /^#!\s*$/

          code_body = code_lines.join("\n").strip
          tokens = options_raw.split
          executable = tokens.includes?("run")

          output << build_code_window(lang, code_body, executable: executable)
        else
          output << line
          i += 1
        end
      end

      output.join("\n")
    end

    private def pipeline_practice_blocks(content, page)
      html = content.dup
      
      # Match practice blocks: #> ruby :practice ... #!
      # Pattern matches from #> ruby :practice to #! (must be at start of line)
      pattern = %r{(^|\n)#>\s*ruby\s*:practice\s*\n([\s\S]*?)^#!\s*$}m
      
      practice_index = 0
      html = html.gsub(pattern) do |practice_block|
        result = if match = pattern.match(practice_block)
          prefix = match[1]?.to_s || ""
          inner_content = match[2]?.to_s || ""
          
          # Extract TODO/initial code (everything before ```solution)
          # This includes any markdown content like **Goal:** lines and TODO comments
          todo_match = inner_content.match(/^([\s\S]*?)(?=```solution)/m)
          todo_content = todo_match && todo_match[1]? ? todo_match[1].to_s : ""
          
          # Filter out non-code lines (like **Goal:** markdown) - keep only lines that look like code/TODO comments
          # Keep lines that start with # (comments) or are blank, remove markdown formatting lines
          todo_lines = todo_content.lines.select do |line|
            stripped = line.strip
            stripped.empty? || stripped.starts_with?("#") || !stripped.match(/^\*\*/)
          end
          todo_code = todo_lines.join("\n").strip
          
          # Extract solution code block
          solution_match = inner_content.match(/```solution\s*\n([\s\S]*?)```/m)
          solution_code = solution_match && solution_match[1]? ? solution_match[1].to_s.strip : ""
          
          # Extract test code block
          test_match = inner_content.match(/```test\s*\n([\s\S]*?)```/m)
          test_code = test_match && test_match[1]? ? test_match[1].to_s.strip : ""
          
          # Generate practice chapter identifier from page permalink
          permalink = page["permalink"]?.to_s || ""
          practice_chapter = "rl:chapter:#{permalink.chomp('/')}"
          
          current_index = practice_index
          practice_index += 1
          
          # Build the HTML structure for practice block
          replacement = <<-HTML
          <pre class="language-ruby"
               data-executable="true"
               data-practice-chapter="#{practice_chapter}"
               data-practice-index="#{current_index}"
               data-test="#{HTML.escape(test_code)}"><code class="language-ruby">#{HTML.escape(todo_code)}</code></pre>
          <div class="practice-feedback"
               data-practice-chapter="#{practice_chapter}"
               data-practice-index="#{current_index}"></div>
          
          <script type="text/plain"
                  data-practice-solution="#{practice_chapter}:#{current_index}">
          #{solution_code}
          </script>
          HTML
          "#{prefix}#{replacement}"
        else
          practice_block
        end
        result
      end
      html
    end

    private def pipeline_ruby_pre_blocks(content, page)
      html = content.dup
      
      # 1. Find code windows (for is_inside check)
      code_window_ranges = [] of {Int32, Int32}
      pos = 0
      while match = /<div class="code-window">/.match(html, pos)
        start_pos = match.begin(0)
        scan_pos = match.end(0)
        depth = 1
        
        while depth > 0
           next_tag = html.index(/<div|<\/div>/, scan_pos)
           break unless next_tag
           scan_pos = next_tag
           
           if html[scan_pos..].starts_with?("<div")
             depth += 1
           elsif html[scan_pos..].starts_with?("</div")
             depth -= 1
           end
           scan_pos += 1
        end
        
        end_pos = scan_pos
        code_window_ranges << {start_pos, end_pos}
        pos = end_pos
      end
      
      is_inside_code_window = ->(pos : Int32) {
        code_window_ranges.any? { |range| pos >= range[0] && pos < range[1] }
      }

      # 2. Find all pre blocks
      # We use a loop instead of gsub to avoid regex "huge match" issues and ensure we handle nested structures correctly.
      new_html = String.build do |str|
        pos = 0
        wrapped_count = 0
        
        while match = /<pre([^>]*)>/.match(html, pos)
          pre_start = match.begin(0)
          attrs = match[1]
          
          # Append text before pre
          str << html[pos...pre_start]
          
          # Find end of pre
          pre_end_match = /<\/pre>/.match(html, pre_start)
          if pre_end_match
            pre_end = pre_end_match.end(0)
            pre_content_full = html[pre_start...pre_end]
            
            # Check if we should process this block
            should_process = false
            if attrs.includes?("language-ruby") || attrs.includes?("data-executable")
               should_process = true
            end
            
            if should_process && !is_inside_code_window.call(pre_start)
              wrapped_count += 1
              
              # Extract practice attributes
              practice_chapter = nil
              practice_index = nil
              practice_test = nil
              
              if practice_match = pre_content_full.match(/data-practice-chapter\s*=\s*"([^"]+)"/)
                practice_chapter = practice_match[1]?.to_s
              end
              if practice_match = pre_content_full.match(/data-practice-index\s*=\s*"([^"]+)"/)
                practice_index = practice_match[1]?.to_s
              end
              if practice_match = pre_content_full.match(/data-test\s*=\s*"([^"]+)"/)
                practice_test = practice_match[1]?.to_s
              end
              
              # Extract code content
              code_match = pre_content_full.match(/<code[^>]*>([\s\S]*?)<\/code>/m)
              code_content = code_match && code_match[1]? ? code_match[1].to_s : ""
              code_content = code_content.strip
              
              # Helper to unescape then escape
              unescape_then_escape = ->(value : String) {
                unescaped = value.gsub("&amp;", "&").gsub("&lt;", "<").gsub("&gt;", ">").gsub("&quot;", "\"").gsub("&#39;", "'")
                HTML.escape(unescaped)
              }
              
              pre_attrs = %(class="language-ruby" data-executable="true")
              pre_attrs += %( data-practice-chapter="#{unescape_then_escape.call(practice_chapter)}") if practice_chapter
              pre_attrs += %( data-practice-index="#{unescape_then_escape.call(practice_index)}") if practice_index
              pre_attrs += %( data-test="#{unescape_then_escape.call(practice_test)}") if practice_test
              
              preserved_pre = %(<pre #{pre_attrs}><code class="language-ruby">#{code_content}</code></pre>)
              
              str << <<-HTML
                <div class="code-window">
                  <div class="code-header">
                    <span class="window-btn red"></span>
                    <span class="window-btn yellow"></span>
                    <span class="window-btn green"></span>
                    <span class="window-title">ruby.rb</span>
                  </div>
                  <div class="code-content">
                    <div class="code-editor">
                      #{preserved_pre}
                    </div>
                  </div>
                </div>
              HTML
            else
              # Don't wrap
              str << pre_content_full
            end
            
            pos = pre_end
          else
            # No closing pre? Just append the rest
            str << html[pre_start..-1]
            pos = html.size
            break
          end
        end
        str << html[pos..-1]
      end
      
      new_html
    end

    private def pipeline_ruby_exec(content, page)
      html = content.dup
      count = 0
      # Process ruby-exec blocks using gsub with replacement string
      # Match the Ruby version's pattern: ```ruby-exec[ \t]*\r?\n(.*?)```
      # In Crystal, . does NOT match newlines even with m flag, so use [\s\S]*?
      html = html.gsub(/```ruby-exec[ \t]*\r?\n([\s\S]*?)```/) do |full_match|
        # Re-match the full match to extract groups
        if m = /```ruby-exec[ \t]*\r?\n([\s\S]*?)```/.match(full_match)
          code_content = m[1]?.to_s.strip || ""
          count += 1

          build_code_window("ruby", code_content, executable: true)
        else
          full_match
        end
      end

      html
    end
    
    private def pipeline_markdown(content, page)
      html = content.dup
      

      # Count how many ruby-exec blocks are still in the content at this stage
      ruby_exec_count = html.scan(/```ruby-exec/).size



      # Handle fenced code blocks BEFORE any other markdown transforms
      # so lines starting with '#' inside fences don't turn into headings.
      # Skip ruby-exec blocks as they should have been processed by pipeline_ruby_exec
      # (but handle them as fallback if they weren't converted)
      html = html.gsub(/```([a-z-]*)[ \t]*\r?\n([\s\S]*?)```/m) do |match|
        if code_match = /```([a-z-]*)[ \t]*\r?\n([\s\S]*?)```/m.match(match)
          lang = code_match[1]?.to_s || ""
          code_content = code_match[2]?.to_s.rstrip || ""

          case lang
          when "ruby-exec"
            # Skip - already processed by pipeline_ruby_exec step
            match
          when "solution", "test"
            match
          else
            # "*-exec" fences (e.g. python-exec) become executable code
            # windows wired to the matching in-browser runtime, mirroring
            # the Ruby engine's handle_code_fences.
            if exec_match = lang.match(/^(.+)-exec$/)
              build_code_window(exec_match[1], code_content, true)
            else
              language = lang.empty? ? nil : lang
              build_code_window(language, code_content, false)
            end
          end
        else
          match
        end
      end

      # Protect all <pre> and <script> blocks from further markdown transforms
      pre_blocks = [] of String
      html = html.gsub(/<pre[^>]*>[\s\S]*?<\/pre>/m) do |block|
        token = "TOKEN_PRE_#{pre_blocks.size}_TOKEN"
        pre_blocks << block
        token
      end

      script_blocks = [] of String
      html = html.gsub(/<script[^>]*>[\s\S]*?<\/script>/m) do |block|
        token = "TOKEN_SCRIPT_#{script_blocks.size}_TOKEN"
        script_blocks << block
        token
      end
      
      # Also protect code-window divs from paragraph wrapping

      # Use robust detection logic to handle nested divs
      code_window_blocks = [] of String
      code_window_ranges = [] of {Int32, Int32}
      pos = 0
      while match = /<div class="code-window">/.match(html, pos)
        start_pos = match.begin(0)
        scan_pos = start_pos + 1
        depth = 1
        
        while depth > 0
           next_tag = html.index(/<div|<\/div>/, scan_pos)
           break unless next_tag
           scan_pos = next_tag
           
           if html[scan_pos..].starts_with?("<div")
             depth += 1
           elsif html[scan_pos..].starts_with?("</div")
             depth -= 1
           end
           scan_pos += 1
        end
        
        end_pos = scan_pos
        code_window_ranges << {start_pos, end_pos}
        pos = end_pos
      end
      
      # Extract blocks in order
      code_window_ranges.each do |range|
        code_window_blocks << html[range[0]...range[1]]
      end
      

      

      
      # Replace in reverse order to preserve indices

      i = code_window_ranges.size - 1
      code_window_ranges.reverse_each do |range|
        start_pos, end_pos = range
        token = "TOKEN_CODEWINDOW_#{i}_TOKEN"
        html = html[0...start_pos] + token + html[end_pos..-1]
        i -= 1
      end

      # Headings: lines starting with one or more '#' characters.
      # Use an explicit "start-of-line or newline" prefix so Crystal's regex
      # engine reliably matches headings anywhere in the content.
      html = html.gsub(/(^|\n)(#+)\s+(.+)/) do |match|
        if heading_match = /(^|\n)(#+)\s+(.+)/.match(match)
          prefix = heading_match[1]?.to_s || ""
          marks  = heading_match[2]?.to_s || ""
          level  = marks.size
          heading_text = heading_match[3]?.to_s || ""
          slug = nil

          if slug_match = heading_text.match(/\s*\{#([^}]+)\}\s*$/)
            slug = slug_match[1]?.to_s
            heading_text = heading_text.sub(/\s*\{#([^}]+)\}\s*$/, "")
          end

          heading_text = heading_text.strip

          rendered = if slug
                       "<h#{level} id=\"#{slug}\">#{heading_text}</h#{level}>"
                     else
                       "<h#{level}>#{heading_text}</h#{level}>"
                     end

          "#{prefix}#{rendered}"
        else
          match
        end
      end

      # Lists: runs of "- " lines become <ul>, runs of "1. " lines become
      # <ol>. Line-based, mirroring the Ruby renderer.
      list_lines = html.split("\n")
      list_out = [] of String
      list_type = :none
      list_lines.each do |line|
        if item_match = /\A[ \t]*\-\s+(.+?)\s*\z/.match(line)
          if list_type == :ol
            list_out << "</ol>"
            list_type = :none
          end
          if list_type != :ul
            list_out << "<ul>"
            list_type = :ul
          end
          list_out << "<li>#{item_match[1]}</li>"
        elsif item_match = /\A[ \t]*\d+\.\s+(.+?)\s*\z/.match(line)
          if list_type == :ul
            list_out << "</ul>"
            list_type = :none
          end
          if list_type != :ol
            list_out << "<ol>"
            list_type = :ol
          end
          list_out << "<li>#{item_match[1]}</li>"
        else
          if list_type == :ul
            list_out << "</ul>"
          elsif list_type == :ol
            list_out << "</ol>"
          end
          list_type = :none
          list_out << line
        end
      end
      list_out << "</ul>" if list_type == :ul
      list_out << "</ol>" if list_type == :ol
      html = list_out.join("\n")

      # Paragraphs
      # Split by double newlines to properly create paragraphs
      html = html.split(/\n\n+/).map do |chunk|
        trimmed = chunk.strip
        next if trimmed.empty?
      
        "<p>#{trimmed}</p>"
      end.compact.join("\n")


      # Clean up <p> tags around block elements
      html = html.gsub(/<p>(<\/?(?:h[1-6]|pre|ul|ol|li|div|p)[^>]*>)<\/p>/m, "\\1")
      html = html.gsub(/<p>\s*(<\/(?:h[1-6]|pre|ul|ol|li|div|p)>)\s*<\/p>/m, "\\1")
      # Also handle cases where block element is at start/end of p content
      html = html.gsub(/<p>\s*(<(?:h[1-6]|pre|ul|ol|li|div|p)[^>]*>.*?<\/(?:h[1-6]|pre|ul|ol|li|div|p)>)\s*<\/p>/m, "\\1")
      html = html.gsub(/<p>\s*(<div[^>]*>[\s\S]*?<\/div>)\s*<\/p>/m, "\\1")
      html = html.gsub(/<p>\s*(<pre[^>]*>[\s\S]*?<\/pre>)\s*<\/p>/m, "\\1")

      # Bold (**text**)
      html = html.gsub(/\*\*([^*]+)\*\*/) do |match|
        if bold_match = /\*\*([^*]+)\*\*/.match(match)
          "<strong>#{bold_match[1]?.to_s || ""}</strong>"
        else
          match
        end
      end

      # Inline code `code`
      html = html.gsub(/`([^`]+)`/) do |match|
        if code_match = /`([^`]+)`/.match(match)
          code_content = code_match[1]?.to_s || ""
          code_content = code_content.gsub("<", "&lt;").gsub(">", "&gt;")
          "<code>#{code_content}</code>"
        else
          match
        end
      end

      # Links [text](url)
      html = html.gsub(/\[([^\]]+)\]\(([^\)]+)\)/) do |match|
        if link_match = /\[([^\]]+)\]\(([^\)]+)\)/.match(match)
          text = link_match[1]?.to_s || ""
          url = link_match[2]?.to_s || ""
          %(<a href="#{url}">#{text}</a>)
        else
          match
        end
      end

      # Restore code-window blocks FIRST (because they may contain PRE tokens)
      code_window_blocks.each_with_index do |block, i|
        html = html.gsub("TOKEN_CODEWINDOW_#{i}_TOKEN") { block }
      end

      # Restore protected <pre> and <script> blocks
      pre_blocks.each_with_index do |block, i|
        html = html.gsub("TOKEN_PRE_#{i}_TOKEN") { block }
      end
      
      script_blocks.each_with_index do |block, i|
        html = html.gsub("TOKEN_SCRIPT_#{i}_TOKEN") { block }
      end

      "<div class='markdown'>#{html}</div>"
    end

    # Collapse nested code-window wrappers so that we never end up
    # with a code-window inside another code-window. Keep the inner
    # window (which contains the actual <pre> block).
    private def normalize_code_windows(html : String) : String
      pattern = %r{
        <div\s+class="code-window">\s*
          <div\s+class="code-header">.*?</div>\s*
          <div\s+class="code-content">\s*
            <div\s+class="code-editor">\s*
              (?<inner><div\s+class="code-window">.*?</div>)\s*
            </div>\s*
          </div>\s*
        </div>
      }mx

      html.gsub(pattern) do |match|
        if m = pattern.match(match)
          m["inner"]? || match
        else
          match
        end
      end
    end

    private def build_code_window(language : String?, code_body : String, executable : Bool)
      # Match the Ruby builder's semantics so HTML and CSS hooks line up.
      lang = language
      lang = nil if lang && lang.empty?

      window_title = if lang
                       "#{lang}.#{lang == "ruby" ? "rb" : lang}"
                     else
                       "code"
                     end
      window_title = "ruby.rb" if lang == "ruby"

      code_lang = lang || "code"
      code_classes = ["language-#{code_lang}"]
      code_classes << "#{code_lang}-exec" if executable

      pre_classes = ["code-editor__highlight"]
      pre_classes << "language-ruby" if lang == "ruby"

      pre_attributes = [] of String
      pre_attributes << %(class="#{pre_classes.join(" ")}")
      pre_attributes << %(data-executable="true") if executable
      pre_attributes << %(style="white-space: pre-wrap; outline: none;")
      pre_attr = pre_attributes.any? ? " " + pre_attributes.join(" ") : ""

      code_attr = %(class="#{code_classes.join(" ")}")
      escaped_code = HTML.escape(code_body)

      <<-HTML
        <div class="code-window">
          <div class="code-header">
            <span class="window-btn red"></span>
            <span class="window-btn yellow"></span>
            <span class="window-btn green"></span>
            <span class="window-title">#{window_title}</span>
          </div>
          <div class="code-content">
            <div class="code-editor">
              <pre#{pre_attr}><code #{code_attr}>#{escaped_code}</code></pre>
            </div>
          </div>
        </div>
      HTML
    end

    private def find_layout_path(layout_name : String, theme_name : String) : String?
      candidates = [] of String

      if Dir.exists?(@site_layouts_dir)
        candidates << File.join(@site_layouts_dir, "#{layout_name}.html")
        candidates << File.join(@site_layouts_dir, "#{layout_name}.liquid")
      end

      theme_path = @theme_paths[theme_name]? || @theme_path
      if theme_path && Dir.exists?(File.join(theme_path, "layouts"))
        candidates << File.join(theme_path, "layouts", "#{layout_name}.html")
        candidates << File.join(theme_path, "layouts", "#{layout_name}.liquid")
      end

      # Fallback: default theme layouts (themes like pylearning inherit them)
      if @theme_path && Dir.exists?(File.join(@theme_path, "layouts"))
        candidates << File.join(@theme_path, "layouts", "#{layout_name}.html")
        candidates << File.join(@theme_path, "layouts", "#{layout_name}.liquid")
      end

      candidates.find { |path| File.exists?(path) }
    end

    private def render_inline_template(template_body : String, page_data : Hash(String, YAML::Any), theme_name : String) : String
      template = Liquid::Template.parse(template_body)
      template.template_path = includes_dir_for(theme_name)
      ctx = Liquid::Context.new
      ctx.set("site", hash_to_liquid_value(@site))
      ctx.set("page", hash_to_liquid_value(page_data))
      ctx.set("content", Liquid::Any.new(""))
      template.render(ctx)
    end

    private def render_layout(layout_name : String, content : String, page_data : Hash(String, YAML::Any), theme_name : String) : String
      return content if layout_name.empty?

      layout_path = find_layout_path(layout_name, theme_name)
      raise "Missing layout: #{layout_name}" unless layout_path

      layout_front_matter, layout_template_body = extract_front_matter_from_layout(File.read(layout_path))

      begin
        template = Liquid::Template.parse(layout_template_body)
        template.template_path = includes_dir_for(theme_name)

        ctx = Liquid::Context.new
        ctx.set("site", hash_to_liquid_value(@site))
        ctx.set("page", hash_to_liquid_value(page_data))
        ctx.set("content", Liquid::Any.new(content))

        rendered = template.render(ctx)
      rescue ex
        Log.error(exception: ex) { "Failed to render layout #{layout_name} (theme: #{theme_name})" }
        raise ex
      end

      parent_layout_any = layout_front_matter["layout"]?
      if parent_layout_any && (parent_layout = parent_layout_any.as_s?) && !parent_layout.empty?
        render_layout(parent_layout, rendered, page_data, theme_name)
      else
        rendered
      end
    end

    private def extract_front_matter_from_layout(raw_layout_content : String) : Tuple(Hash(String, YAML::Any), String)
      if match = raw_layout_content.match(/\A---\n(.+?)\n---\n(.*)/m)
        front_matter_raw = match[1]?.to_s || ""
        body = match[2]?.to_s || ""
        begin
          data = Typophic::Util.yaml_hash_to_string_keys(YAML.parse(front_matter_raw).as_h)
          return {data, body}
        rescue ex
          Log.warn { "Failed to parse front matter in layout: #{ex.message}" }
          return {Hash(String, YAML::Any).new, raw_layout_content}
        end
      else
        return {Hash(String, YAML::Any).new, raw_layout_content}
      end
    end

    # Helper to convert Hash(String, YAML::Any) to Liquid::Any
    private def hash_to_liquid_value(hash : Hash(String, YAML::Any)) : Liquid::Any
      converted_hash = {} of String => Liquid::Any
      hash.each do |k, v|
        converted = Typophic::Util.yaml_any_to_crystal(v)
        # Convert to Liquid::Any::Type
        liquid_value = case converted
        when String then converted
        when Int64 then converted
        when Float64 then converted
        when Bool then converted
        when Nil then nil
        when Hash(String, Liquid::Any) then converted
        when Array(Liquid::Any) then converted
        else
          converted.to_s
        end
        converted_hash[k] = Liquid::Any.new(liquid_value)
      end
      Liquid::Any.new(converted_hash)
    end

    private def write_collection_indexes
      return if @collections.empty?

      data_dir = File.join(@output_dir, "typophic")
      FileUtils.mkdir_p(data_dir)

      @collections.each do |section, pages|
        summaries = pages.map do |page|
          tags_any = page["tags"]?
          tags = if tags_any && (tags_arr = tags_any.as_a?)
                   tags_arr.map(&.to_s)
                 else
                   [] of String
                 end
          
          {
            "title" => page["title"]?.try(&.to_s) || "",
            "description" => page["description"]?.try(&.to_s),
            "permalink" => page["permalink"]?.try(&.to_s) || "",
            "url" => page["url"]?.try(&.to_s) || "",
            "date" => serialize_date(page["date"]?),
            "tags" => tags
          }
        end

        json_output = JSON.build do |json|
          json.array do
            summaries.each do |summary|
              json.object do
                json.field "title", summary["title"]?.to_s || ""
                json.field "description", summary["description"]?.to_s if summary["description"]?
                json.field "permalink", summary["permalink"]?.to_s || ""
                json.field "url", summary["url"]?.to_s || ""
                json.field "date", summary["date"]?.to_s if summary["date"]?
                json.field "tags" do
                  json.array do
                    tags_array = summary["tags"]?
                    if tags_array.is_a?(Array)
                      tags_array.each do |tag|
                        json.string tag.to_s
                      end
                    end
                  end
                end
              end
            end
          end
        end
        
        File.write(
          File.join(data_dir, "#{section}.json"),
          json_output
        )
      end
    end

    private def serialize_date(value : YAML::Any?)
      return nil unless value
      if value.raw.is_a?(Time)
        return value.raw.as(Time).to_s("%Y-%m-%d")
      end
      value.to_s
    end

    private def load_helpers
      # Placeholder - helper loading not yet implemented in Crystal
      [] of String
    end

    private def includes_dir_for(theme_name : String) : String
      cached = @include_dir_cache[theme_name]?
      return cached if cached && Dir.exists?(cached)

      dir = File.join(Dir.tempdir, "typophic-includes-#{theme_name}")
      FileUtils.rm_rf(dir) if Dir.exists?(dir)
      FileUtils.mkdir_p(dir)

      include_sources = [] of String
      include_sources << @site_includes_dir if Dir.exists?(@site_includes_dir)

      current_theme_path = @theme_paths[theme_name]?
      include_sources << File.join(current_theme_path, "includes") if current_theme_path && Dir.exists?(File.join(current_theme_path, "includes"))

      if @theme_paths.has_key?("rubylearning")
        rubylearning_includes = File.join(@theme_paths["rubylearning"], "includes")
        include_sources << rubylearning_includes if Dir.exists?(rubylearning_includes)
      end

      include_sources.each do |src|
        Dir.glob(File.join(src, "*")).each do |file|
          next unless File.file?(file)
          target = File.join(dir, File.basename(file))
          next if File.exists?(target)

          FileUtils.cp(file, target)
        end
      end

      @include_dir_cache[theme_name] = dir
      dir
    end
  end
end
