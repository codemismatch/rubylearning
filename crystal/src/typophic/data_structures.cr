# frozen_string_literal: true

require "yaml"
require "./util"

module Typophic
  # A struct to hold page data for easy access in templates.
  struct Page
    getter layout : String
    getter section : String
    getter type : String
    getter source : String
    getter slug : String
    getter date : Time?
    getter date_iso : String?
    getter permalink : String
    getter url : String
    getter output_path : String
    getter title : String
    getter tags : Array(String)
    getter description : String? # For blog posts etc.
    getter meta : Hash(String, YAML::Any) # Any other front matter data

    def initialize(hash : Hash(String, YAML::Any))
      @layout = hash["layout"]?.try(&.as_s) || ""
      @section = hash["section"]?.try(&.as_s) || ""
      @type = hash["type"]?.try(&.as_s) || ""
      @source = hash["source"]?.try(&.as_s) || ""
      @slug = hash["slug"]?.try(&.as_s) || ""
      @date = hash["date"]?.try(&.as_t)
      @date_iso = @date.try &.to_s("%Y-%m-%d")
      @permalink = hash["permalink"]?.try(&.as_s) || ""
      @url = hash["url"]?.try(&.as_s) || ""
      @output_path = hash["output_path"]?.try(&.as_s) || ""
      @title = hash["title"]?.try(&.as_s) || ""
      
      tags_any = hash["tags"]?
      @tags = if tags_any && (tags_arr = tags_any.as_a?)
                tags_arr.map(&.to_s)
              else
                [] of String
              end
      @description = hash["description"]?.try(&.as_s)

      # Remaining hash keys
      remaining_hash = hash.dup
      {"layout", "section", "type", "source", "slug", "date", "date_iso", "permalink", "url", "output_path", "title", "tags", "description"}.each do |key|
        remaining_hash.delete(key)
      end
      @meta = remaining_hash # Keep as YAML::Any for now
    end

    def to_liquid
      {
        "layout" => @layout,
        "section" => @section,
        "type" => @type,
        "source" => @source,
        "slug" => @slug,
        "date" => @date,
        "date_iso" => @date_iso,
        "permalink" => @permalink,
        "url" => @url,
        "output_path" => @output_path,
        "title" => @title,
        "tags" => @tags,
        "description" => @description
      }.merge(@meta.transform_values { |v| v.raw }) # Convert YAML::Any to raw Crystal types for Liquid
    end
  end

  # A struct to hold site-wide data.
  struct Site
    getter base_url : String
    getter base_path : String
    getter title : String
    getter data : Hash(String, YAML::Any) # Data from /data directory
    getter config : Hash(String, YAML::Any) # Raw config.yml
    property archives : Array(Hash(String, YAML::Any))
    property tags : Array(Hash(String, YAML::Any))
    property collections : Hash(String, Array(Hash(String, YAML::Any)))


    def initialize(hash : Hash(String, YAML::Any))
      @base_url = hash["base_url"]?.try(&.as_s) || ""
      @base_path = hash["base_path"]?.try(&.as_s) || ""
      @title = hash["title"]?.try(&.as_s) || "Typophic Site"

      @data = Typophic::Util.yaml_hash_to_string_keys(hash["data"]?.try(&.as_h))
      @config = Typophic::Util.yaml_hash_to_string_keys(hash)

      # These are populated later, initialize as empty
      @archives = [] of Hash(String, YAML::Any)
      @tags = [] of Hash(String, YAML::Any)
      @collections = Hash(String, Array(Hash(String, YAML::Any))).new
    end

    def to_liquid
      {
        "base_url" => @base_url,
        "base_path" => @base_path,
        "title" => @title,
        "data" => Typophic::Util.yaml_any_to_crystal(YAML::Any.new(@data)),
        "config" => Typophic::Util.yaml_any_to_crystal(YAML::Any.new(@config)),
        "archives" => Typophic::Util.yaml_any_to_crystal(YAML::Any.new(@archives)),
        "tags" => Typophic::Util.yaml_any_to_crystal(YAML::Any.new(@tags)),
        "collections" => Typophic::Util.yaml_any_to_crystal(YAML::Any.new(@collections))
      }
    end
  end
end
