# frozen_string_literal: true

require "yaml"
require "json"

module Typophic
  module Util
    # Recursively converts a YAML::Any into a basic Crystal type
    # Returns a type that Liquid can handle - using JSON::Any as intermediate format
    def self.yaml_any_to_crystal(value : YAML::Any)
      # Convert YAML::Any to JSON::Any first, then to Crystal types
      # This avoids recursive type issues
      json_any = yaml_to_json_any(value)
      json_any_to_crystal(json_any)
    end
    
    private def self.yaml_to_json_any(value : YAML::Any) : JSON::Any
      case v_raw = value.raw
      when String then JSON::Any.new(v_raw)
      when Int32, Int64, Int128 then JSON::Any.new(v_raw.to_i64)
      when Float32, Float64 then JSON::Any.new(v_raw.to_f64)
      when Bool then JSON::Any.new(v_raw)
      when Time then JSON::Any.new(v_raw.to_s)
      when Nil then JSON::Any.new(nil)
      when Hash
        json_hash = {} of String => JSON::Any
        v_raw.as(Hash).each do |k, v|
          json_hash[k.to_s] = yaml_to_json_any(v.as(YAML::Any))
        end
        JSON::Any.new(json_hash)
      when Array
        json_array = v_raw.as(Array).map { |v| yaml_to_json_any(v.as(YAML::Any)) }
        JSON::Any.new(json_array)
      else
        JSON::Any.new(v_raw.to_s)
      end
    end
    
    private def self.json_any_to_crystal(value : JSON::Any)
      case value.raw
      when String then value.as_s
      when Int64 then value.as_i64
      when Float64 then value.as_f
      when Bool then value.as_bool
      when Nil then nil
      when Hash
        # Convert to Hash(String, Liquid::Any) for Liquid compatibility
        result = {} of String => Liquid::Any
        value.as_h.each do |k, v|
          result[k] = Liquid::Any.new(json_any_to_liquid_any(v))
        end
        result
      when Array
        # Convert to Array(Liquid::Any) for Liquid compatibility
        value.as_a.map { |v| Liquid::Any.new(json_any_to_liquid_any(v)) }
      else
        value.to_s
      end
    end
    
    # Convert JSON::Any to Liquid::Any::Type
    private def self.json_any_to_liquid_any(value : JSON::Any) : Liquid::Any::Type
      case value.raw
      when String then value.as_s
      when Int64 then value.as_i64
      when Float64 then value.as_f
      when Bool then value.as_bool
      when Nil then nil
      when Hash
        result = {} of String => Liquid::Any
        value.as_h.each do |k, v|
          result[k] = Liquid::Any.new(json_any_to_liquid_any(v))
        end
        result
      when Array
        value.as_a.map { |v| Liquid::Any.new(json_any_to_liquid_any(v)) }
      else
        value.to_s
      end
    end

    # Helper to ensure hash keys are strings, for Liquid context compatibility
    def self.yaml_hash_to_string_keys(hash : Hash(YAML::Any, YAML::Any)?) : Hash(String, YAML::Any)
      return Hash(String, YAML::Any).new unless hash
      new_hash = Hash(String, YAML::Any).new
      hash.each do |k, v|
        new_hash[k.to_s] = v.as(YAML::Any)
      end
      new_hash
    end

    def self.yaml_hash_to_string_keys(hash : Hash(String, YAML::Any)?) : Hash(String, YAML::Any)
      return Hash(String, YAML::Any).new unless hash
      hash
    end
  end
end
