require "file_utils"
require "yaml"

module Typophic
  class ThemeImporter
    record Result,
      name : String,
      target_path : String,
      source_path : String,
      copied : Array(String),
      rewritten : Array(String),
      warnings : Array(String) do
      
      def summary_lines : Array(String)
        lines = [] of String
        lines << "Copied: #{copied.join(", ")}" unless copied.empty?
        lines << "Rewritten templates: #{rewritten.size}" unless rewritten.empty?
        lines << "Warnings: #{warnings.size}" unless warnings.empty?
        lines
      end
    end

    def initialize(@target_root : String = "themes", @staging_root : String = File.join("tmp", "theme-import"))
    end

    def import(source : String, name : String? = nil) : Result
      staging_dir : String? = nil
      cleanup_dir : String? = nil

      source_root, cleanup_dir, staged = resolve_source_root(source)
      staging_dir = staged ? source_root : stage_source(source_root)

      theme_name = slugify(name || File.basename(source_root))
      target_path = File.join(@target_root, theme_name)
      
      if Dir.exists?(target_path)
        raise "Target theme already exists at #{target_path}"
      end

      result = Result.new(
        name: theme_name,
        target_path: target_path,
        source_path: source_root,
        copied: [] of String,
        rewritten: [] of String,
        warnings: [] of String
      )

      FileUtils.mkdir_p(target_path)

      mapping = detect_paths(staging_dir)
      result.warnings << "No layouts found (layouts/ or _layouts/)" unless mapping[:layouts]
      result.warnings << "No includes found (includes/ or _includes/)" unless mapping[:includes]
      result.warnings << "No Sass partials found (_sass/)" unless mapping[:sass]
      result.warnings << "No assets directories found (assets, css, js, images, fonts, static, media)" if mapping[:assets].empty?

      copy_if_present(mapping[:layouts], File.join(target_path, "layouts"), result, "layouts")
      copy_if_present(mapping[:includes], File.join(target_path, "includes"), result, "includes")
      copy_if_present(mapping[:sass], File.join(target_path, "_sass"), result, "_sass")
      copy_assets(mapping[:assets], target_path, result)
      copy_if_present(mapping[:data], File.join(target_path, "data"), result, "data")

      rewrite_templates(File.join(target_path, "layouts"), result)
      rewrite_templates(File.join(target_path, "includes"), result)
      rewrite_templates(File.join(target_path, "assets"), result)

      write_manifest(target_path, result)

      result
    ensure
      FileUtils.rm_rf(staging_dir) if staging_dir && Dir.exists?(staging_dir)
      FileUtils.rm_rf(cleanup_dir) if cleanup_dir && Dir.exists?(cleanup_dir)
    end

    private def resolve_source_root(source : String) : Tuple(String, String?, Bool)
      expanded = File.expand_path(source)
      return {expanded, nil, false} if Dir.exists?(expanded)

      if git_source?(source)
        dir = fetch_git(source)
        return {dir, dir, true}
      end

      if archive_source?(expanded)
        dir = extract_archive(expanded)
        return {dir, dir, true}
      end

      raise "Source path not found or unsupported: #{source}"
    end

    private def stage_source(path : String) : String
      FileUtils.mkdir_p(@staging_root)
      tmp = File.tempname("theme-import-", @staging_root)
      FileUtils.mkdir_p(tmp)
      
      # Copy all contents from source to staging
      Dir.glob(File.join(path, "*")).each do |item|
        dest = File.join(tmp, File.basename(item))
        if File.directory?(item)
          FileUtils.cp_r(item, dest)
        else
          FileUtils.cp(item, dest)
        end
      end
      
      tmp
    end

    private def detect_paths(root : String)
      {
        layouts: first_existing(root, ["layouts", "_layouts"]),
        includes: first_existing(root, ["includes", "_includes"]),
        sass: first_existing(root, ["_sass"]),
        data: first_existing(root, ["data", "_data"]),
        assets: discover_assets(root)
      }
    end

    private def discover_assets(root : String) : Array(String)
      %w[assets css js images img fonts static media].map do |dir|
        File.join(root, dir)
      end.select { |path| Dir.exists?(path) }
    end

    private def first_existing(root : String, names : Array(String)) : String?
      names.map { |name| File.join(root, name) }.find { |path| Dir.exists?(path) }
    end

    private def copy_if_present(source : String?, destination : String, result : Result, label : String)
      return unless source && Dir.exists?(source)

      FileUtils.mkdir_p(File.dirname(destination))
      
      # Copy directory contents
      Dir.glob(File.join(source, "*")).each do |item|
        dest = File.join(destination, File.basename(item))
        if File.directory?(item)
          FileUtils.cp_r(item, dest)
        else
          FileUtils.mkdir_p(destination) unless Dir.exists?(destination)
          FileUtils.cp(item, dest)
        end
      end
      
      result.copied << "#{label} -> #{destination}"
    end

    private def copy_assets(asset_dirs : Array(String), target_path : String, result : Result)
      asset_dirs.each do |dir|
        dest = File.join(target_path, File.basename(dir))
        copy_if_present(dir, dest, result, File.basename(dir))
      end
    end

    private def rewrite_templates(root : String, result : Result)
      return unless Dir.exists?(root)

      Dir.glob(File.join(root, "**", "*")).each do |file|
        next unless File.file?(file)
        next unless rewritable_extension?(file)

        original = File.read(file)
        rewritten = rewrite_content(original)
        next if rewritten == original

        File.write(file, rewritten)
        result.rewritten << file.sub("#{root}/", "")
      end
    end

    private def rewritable_extension?(file : String) : Bool
      %w[.html .liquid .md .markdown .css .scss].includes?(File.extname(file).downcase)
    end

    private def rewrite_content(content : String) : String
      updated = rewrite_include_paths(content)
      updated = rewrite_baseurl(updated)
      rewrite_hugo_params(updated)
    end

    private def rewrite_include_paths(content : String) : String
      content
        .gsub(/\{\%\s*include\s+['"]?_includes\/([^'"\s]+)['"]?\s*\%\}/, "{% include \\1 %}")
        .gsub(/\{\%\s*include\s+['"]?\/?includes\/([^'"\s]+)['"]?\s*\%\}/, "{% include \\1 %}")
    end

    private def rewrite_baseurl(content : String) : String
      content.gsub(/site\.baseurl/, "site.base_path")
    end

    private def rewrite_hugo_params(content : String) : String
      content
        .gsub(/\{\{\s*\.Site\.BaseURL\s*\|\s*relURL\s*\}\}/, "{{ '/' | url_for }}")
        .gsub(/\{\{\s*\.Site\.BaseURL\s*\}\}/, "{{ '/' | url_for }}")
    end

    private def write_manifest(target_path : String, result : Result)
      manifest = {
        "name" => result.name,
        "imported_from" => result.source_path,
        "imported_at" => Time.utc.to_s("%Y-%m-%dT%H:%M:%SZ"),
        "notes" => result.warnings,
        "components" => {
          "layouts" => Dir.exists?(File.join(target_path, "layouts")),
          "includes" => Dir.exists?(File.join(target_path, "includes")),
          "sass" => Dir.exists?(File.join(target_path, "_sass")),
          "assets" => Dir.exists?(File.join(target_path, "assets"))
        }
      }

      File.write(File.join(target_path, "theme.yml"), manifest.to_yaml)
      result.copied << "theme.yml"
    end

    private def slugify(value : String) : String
      value.strip.downcase.gsub(/[\s_]+/, "-").gsub(/[^a-z0-9\-]/, "")
    end

    private def git_source?(value : String) : Bool
      !!(value =~ %r{\Ahttps?://} || value =~ /\.git\z/ || value =~ %r{\A[\w\.\-]+/[\w\.\-]+(?:#.+)?\z})
    end

    private def archive_source?(path : String) : Bool
      File.file?(path) && !!(path =~ /\.(zip|tar\.gz|tgz|tar)\z/i)
    end

    private def fetch_git(source : String) : String
      url, ref = git_url_and_ref(source)
      FileUtils.mkdir_p(@staging_root)
      dir = File.tempname("theme-git-", @staging_root)
      FileUtils.mkdir_p(dir)
      target = File.join(dir, "repo")

      result = Process.run("git", ["clone", "--depth", "1", url, target], 
                          output: Process::Redirect::Inherit, 
                          error: Process::Redirect::Inherit)
      
      raise "git clone failed for #{url}" unless result.success?

      if ref
        result = Process.run("git", ["-C", target, "checkout", ref],
                            output: Process::Redirect::Inherit,
                            error: Process::Redirect::Inherit)
        unless result.success?
          STDERR.puts "Warning: failed to checkout ref #{ref}, staying on default branch"
        end
      end

      target
    end

    private def git_url_and_ref(source : String) : Tuple(String, String?)
      if source =~ %r{\Ahttps?://} || source =~ /\.git\z/
        {source, nil}
      else
        parts = source.split("#", 2)
        repo = parts[0]
        ref = parts[1]?
        {"https://github.com/#{repo}.git", ref}
      end
    end

    private def extract_archive(path : String) : String
      FileUtils.mkdir_p(@staging_root)
      dir = File.tempname("theme-archive-", @staging_root)
      FileUtils.mkdir_p(dir)

      if path =~ /\.zip\z/i
        result = Process.run("unzip", ["-q", path, "-d", dir],
                            output: Process::Redirect::Inherit,
                            error: Process::Redirect::Inherit)
        raise "unzip failed for #{path}" unless result.success?
      elsif path =~ /\.(tar\.gz|tgz)\z/i
        result = Process.run("tar", ["-xzf", path, "-C", dir],
                            output: Process::Redirect::Inherit,
                            error: Process::Redirect::Inherit)
        raise "tar extract failed for #{path}" unless result.success?
      elsif path =~ /\.tar\z/i
        result = Process.run("tar", ["-xf", path, "-C", dir],
                            output: Process::Redirect::Inherit,
                            error: Process::Redirect::Inherit)
        raise "tar extract failed for #{path}" unless result.success?
      end

      entries = Dir.children(dir)
      root = if entries.size == 1 && Dir.exists?(File.join(dir, entries.first))
        File.join(dir, entries.first)
      else
        dir
      end

      root
    end
  end
end
