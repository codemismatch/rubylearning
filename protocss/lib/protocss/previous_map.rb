# frozen_string_literal: true

require 'base64'
require 'json'

module Protocss
  class PreviousMap
    attr_accessor :annotation, :inline, :map_file, :root, :text, :consumer_cache

    def initialize(css, opts)
      return if opts[:map] == false

      load_annotation(css)
      @inline = @annotation&.start_with?('data:')

      prev = opts[:map]&.[](:prev)
      text = load_map(opts[:from], prev)
      @map_file ||= opts[:from] if opts[:from]
      @root = File.dirname(@map_file) if @map_file
      @text = text if text
    end

    def consumer
      @consumer_cache ||= begin
        # Source map support requires source-map gem
        # For now, return a simple hash-based consumer
        { file: nil, sources: [], mappings: [] }
      end
    end

    private

    def decode_inline(text)
      base_charset_uri = /^data:application\/json;charset=utf-?8;base64,/
      base_uri = /^data:application\/json;base64,/
      charset_uri = /^data:application\/json;charset=utf-?8,/
      uri = /^data:application\/json,/

      uri_match = text.match(charset_uri) || text.match(uri)
      if uri_match
        return URI.decode_www_form_component(text[uri_match[0].length..-1])
      end

      base_uri_match = text.match(base_charset_uri) || text.match(base_uri)
      if base_uri_match
        return Base64.decode64(text[base_uri_match[0].length..-1])
      end

      encoding = text.match(/data:application\/json;([^,]+),/)[1]
      raise StandardError, "Unsupported source map encoding #{encoding}"
    end

    def get_annotation_url(source_map_string)
      source_map_string.sub(/^\/\*\s*# sourceMappingURL=/, '').strip
    end

    def is_map(map)
      return false unless map.is_a?(Hash)
      map[:mappings].is_a?(String) || map['mappings'].is_a?(String) ||
        map[:_mappings].is_a?(String) || map['_mappings'].is_a?(String) ||
        map[:sections].is_a?(Array) || map['sections'].is_a?(Array)
    end

    def load_annotation(css)
      comments = css.scan(/\/\*\s*# sourceMappingURL=/)
      return unless comments.any?

      start = css.rindex(comments.last)
      end_pos = css.index('*/', start)

      if start && end_pos
        @annotation = get_annotation_url(css[start...end_pos])
      end
    end

    def load_file(path)
      @root = File.dirname(path)
      if File.exist?(path)
        @map_file = path
        return File.read(path).strip
      end
      nil
    end

    def load_map(file, prev)
      return false if prev == false

      if prev
        if prev.is_a?(String)
          return prev
        elsif prev.is_a?(Proc)
          prev_path = prev.call(file)
          if prev_path
            map = load_file(prev_path)
            raise StandardError, "Unable to load previous source map: #{prev_path}" unless map
            return map
          end
        elsif prev.respond_to?(:to_json)
          return prev.to_json
        else
          raise StandardError, "Unsupported previous source map format: #{prev}"
        end
      elsif @inline
        decode_inline(@annotation)
      elsif @annotation
        map = @annotation
        map = File.join(File.dirname(file), map) if file
        load_file(map)
      end
    end

    def start_with(string, start)
      return false unless string
      string[0...start.length] == start
    end

    def to_h
      {
        annotation: @annotation,
        inline: @inline,
        map_file: @map_file,
        root: @root,
        text: @text
      }
    end
  end
end
