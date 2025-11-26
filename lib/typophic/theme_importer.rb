# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require "yaml"
require "time"
require "shellwords"

module Typophic
  # Repackage a third-party theme into Typophic's layout/asset conventions.
  class ThemeImporter
    Result = Struct.new(:name, :target_path, :source_path, :copied, :rewritten, :warnings, keyword_init: true) do
      def summary_lines
        lines = []
        lines << "Copied: #{copied.join(', ')}" if copied.any?
        lines << "Rewritten templates: #{rewritten.length}" if rewritten.any?
        lines << "Warnings: #{warnings.length}" if warnings.any?
        lines
      end
    end

    def initialize(target_root: "themes", staging_root: File.join("tmp", "theme-import"))
      @target_root = target_root
      @staging_root = staging_root
    end

    def import(source, name: nil)
      staging_dir = nil
      cleanup_dir = nil

      source_root, cleanup_dir, staged = resolve_source_root(source)
      staging_dir = staged ? source_root : stage_source(source_root)

      theme_name = slugify(name || File.basename(source_root))
      target_path = File.join(@target_root, theme_name)
      raise "Target theme already exists at #{target_path}" if Dir.exist?(target_path)

      result = Result.new(
        name: theme_name,
        target_path: target_path,
        source_path: source_root,
        copied: [],
        rewritten: [],
        warnings: []
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
      FileUtils.rm_rf(staging_dir) if staging_dir && Dir.exist?(staging_dir)
      FileUtils.rm_rf(cleanup_dir) if cleanup_dir && Dir.exist?(cleanup_dir)
    end

    private

    def resolve_source_root(source)
      expanded = File.expand_path(source)
      return [expanded, nil, false] if Dir.exist?(expanded)

      if git_source?(source)
        dir = fetch_git(source)
        return [dir, dir, true]
      end

      if archive_source?(expanded)
        dir = extract_archive(expanded)
        return [dir, dir, true]
      end

      raise "Source path not found or unsupported: #{source}"
    end

    def stage_source(path)
      FileUtils.mkdir_p(@staging_root)
      Dir.mktmpdir("theme-import-", @staging_root).tap do |tmp|
        FileUtils.cp_r("#{path}/.", tmp)
      end
    end

    def detect_paths(root)
      {
        layouts: first_existing(root, ["layouts", "_layouts"]),
        includes: first_existing(root, ["includes", "_includes"]),
        sass: first_existing(root, ["_sass"]),
        data: first_existing(root, ["data", "_data"]),
        assets: discover_assets(root)
      }
    end

    def discover_assets(root)
      %w[assets css js images img fonts static media].map do |dir|
        File.join(root, dir)
      end.select { |path| Dir.exist?(path) }
    end

    def first_existing(root, names)
      names.map { |name| File.join(root, name) }.find { |path| Dir.exist?(path) }
    end

    def copy_if_present(source, destination, result, label)
      return unless source && Dir.exist?(source)

      FileUtils.mkdir_p(File.dirname(destination))
      FileUtils.cp_r("#{source}/.", destination)
      result.copied << "#{label} -> #{destination}"
    end

    def copy_assets(asset_dirs, target_path, result)
      asset_dirs.each do |dir|
        dest = File.join(target_path, File.basename(dir))
        copy_if_present(dir, dest, result, File.basename(dir))
      end
    end

    def rewrite_templates(root, result)
      return unless Dir.exist?(root)

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

    def rewritable_extension?(file)
      %w[.html .liquid .md .markdown .css .scss].include?(File.extname(file).downcase)
    end

    def rewrite_content(content)
      updated = rewrite_include_paths(content)
      updated = rewrite_baseurl(updated)
      rewrite_hugo_params(updated)
    end

    def rewrite_include_paths(content)
      content
        .gsub(/\{\%\s*include\s+['"]?_includes\/([^'"\s]+)['"]?\s*\%\}/, '{% include \1 %}')
        .gsub(/\{\%\s*include\s+['"]?\/?includes\/([^'"\s]+)['"]?\s*\%\}/, '{% include \1 %}')
    end

    def rewrite_baseurl(content)
      content.gsub(/site\.baseurl/, "site.base_path")
    end

    def rewrite_hugo_params(content)
      content
        .gsub(/\{\{\s*\.Site\.BaseURL\s*\|\s*relURL\s*\}\}/, "{{ '/' | url_for }}")
        .gsub(/\{\{\s*\.Site\.BaseURL\s*\}\}/, "{{ '/' | url_for }}")
    end

    def write_manifest(target_path, result)
      manifest = {
        "name" => result.name,
        "imported_from" => result.source_path,
        "imported_at" => Time.now.utc.iso8601,
        "notes" => result.warnings,
        "components" => {
          "layouts" => Dir.exist?(File.join(target_path, "layouts")),
          "includes" => Dir.exist?(File.join(target_path, "includes")),
          "sass" => Dir.exist?(File.join(target_path, "_sass")),
          "assets" => Dir.exist?(File.join(target_path, "assets"))
        }
      }

      File.write(File.join(target_path, "theme.yml"), manifest.to_yaml)
      result.copied << "theme.yml"
    end

    def slugify(value)
      value.to_s.strip.downcase.gsub(/[\s_]+/, "-").gsub(/[^a-z0-9\-]/, "")
    end

    def git_source?(value)
      value =~ %r{\Ahttps?://} || value =~ /\.git\z/ || value =~ %r{\A[\w\.\-]+/[\w\.\-]+(?:#.+)?\z}
    end

    def archive_source?(path)
      File.file?(path) && path =~ /\.(zip|tar\.gz|tgz|tar)\z/i
    end

    def fetch_git(source)
      url, ref = git_url_and_ref(source)
      dir = Dir.mktmpdir("theme-git-", @staging_root)
      target = File.join(dir, "repo")

      raise "git clone failed for #{url}" unless system("git clone --depth 1 #{Shellwords.escape(url)} #{Shellwords.escape(target)}")

      if ref
        unless system("git -C #{Shellwords.escape(target)} checkout #{Shellwords.escape(ref)}")
          warn "Warning: failed to checkout ref #{ref}, staying on default branch"
        end
      end

      target
    end

    def git_url_and_ref(source)
      if source =~ %r{\Ahttps?://} || source =~ /\.git\z/
        [source, nil]
      else
        repo, ref = source.split("#", 2)
        ["https://github.com/#{repo}.git", ref]
      end
    end

    def extract_archive(path)
      dir = Dir.mktmpdir("theme-archive-", @staging_root)

      if path =~ /\.zip\z/i
        raise "unzip failed for #{path}" unless system("unzip -q #{Shellwords.escape(path)} -d #{Shellwords.escape(dir)}")
      elsif path =~ /\.(tar\.gz|tgz)\z/i
        raise "tar extract failed for #{path}" unless system("tar -xzf #{Shellwords.escape(path)} -C #{Shellwords.escape(dir)}")
      elsif path =~ /\.tar\z/i
        raise "tar extract failed for #{path}" unless system("tar -xf #{Shellwords.escape(path)} -C #{Shellwords.escape(dir)}")
      end

      entries = Dir.children(dir)
      root = if entries.size == 1 && Dir.exist?(File.join(dir, entries.first))
        File.join(dir, entries.first)
      else
        dir
      end

      root
    end
  end
end
