# frozen_string_literal: true

require 'securerandom'
require_relative 'css_syntax_error'
require_relative 'previous_map'

module Protocss
  class Input
    attr_accessor :css, :file, :id, :has_bom, :document, :map

    def from
      @file || @id
    end

    def initialize(css, opts = {})
      if css.nil? || (!css.is_a?(String) && !css.respond_to?(:to_s))
        raise StandardError, "PostCSS received #{css.inspect} instead of CSS string"
      end

      @css = css.to_s

      if @css[0] == "\uFEFF" || @css[0] == "\uFFFE"
        @has_bom = true
        @css = @css[1..-1]
      else
        @has_bom = false
      end

      @document = @css
      @document = opts[:document].to_s if opts[:document]

      if opts[:from]
        if opts[:from].match?(/^\w+:\/\//) || File.absolute_path?(opts[:from])
          @file = opts[:from]
        else
          @file = File.expand_path(opts[:from])
        end
      end

      if source_map_available? && path_available?
        map = PreviousMap.new(@css, opts)
        if map.text
          @map = map
          file = map.consumer.file
          @file ||= map_resolve(file) if file
        end
      end

      @id = "<input css #{SecureRandom.hex(3)}>" unless @file
      @map.file = from if @map
    end

    def error(message, line = nil, column = nil, opts = {})
      end_column = nil
      end_line = nil
      end_offset = nil
      offset = nil
      result = nil

      if line.is_a?(Hash)
        start = line
        end_pos = column
        if start[:offset].is_a?(Numeric)
          offset = start[:offset]
          pos = from_offset(offset)
          line = pos[:line]
          column = pos[:col]
        else
          line = start[:line]
          column = start[:column]
          offset = from_line_and_column(line, column)
        end
        if end_pos[:offset].is_a?(Numeric)
          end_offset = end_pos[:offset]
          pos = from_offset(end_offset)
          end_line = pos[:line]
          end_column = pos[:col]
        else
          end_line = end_pos[:line]
          end_column = end_pos[:column]
          end_offset = from_line_and_column(end_line, end_column)
        end
      elsif !column
        offset = line
        pos = from_offset(offset)
        line = pos[:line]
        column = pos[:col]
      else
        offset = from_line_and_column(line, column)
      end

      origin = self.origin(line, column, end_line, end_column)
      if origin
        result = CssSyntaxError.new(
          message,
          origin[:end_line] ? { column: origin[:column], line: origin[:line] } : origin[:line],
          origin[:end_line] ? { column: origin[:end_column], line: origin[:end_line] } : origin[:column],
          origin[:source],
          origin[:file],
          opts[:plugin]
        )
      else
        result = CssSyntaxError.new(
          message,
          end_line ? { column: column, line: line } : line,
          end_line ? { column: end_column, line: end_line } : column,
          @css,
          @file,
          opts[:plugin]
        )
      end

      result.input = {
        column: column,
        end_column: end_column,
        end_line: end_line,
        end_offset: end_offset,
        line: line,
        offset: offset,
        source: @css
      }
      if @file
        result.input[:file] = @file
        result.input[:url] = "file://#{@file}"
      end

      result
    end

    def from_line_and_column(line, column)
      line_to_index = get_line_to_index
      index = line_to_index[line - 1]
      index + column - 1
    end

    def from_offset(offset)
      line_to_index = get_line_to_index
      last_line = line_to_index[-1]

      min = 0
      if offset >= last_line
        min = line_to_index.length - 1
      else
        max = line_to_index.length - 2
        while min < max
          mid = min + ((max - min) >> 1)
          if offset < line_to_index[mid]
            max = mid - 1
          elsif offset >= line_to_index[mid + 1]
            min = mid + 1
          else
            min = mid
            break
          end
        end
      end
      {
        col: offset - line_to_index[min] + 1,
        line: min + 1
      }
    end

    def map_resolve(file)
      return file if file.match?(/^\w+:\/\//)
      File.expand_path(file, @map.consumer.source_root || @map.root || '.')
    end

    def origin(line, column, end_line, end_column)
      return false unless @map

      consumer = @map.consumer
      # Simplified origin - full implementation would use source-map gem
      return false unless consumer.is_a?(Hash)

      {
        column: column,
        end_column: end_column,
        end_line: end_line,
        line: line,
        source: nil,
        file: nil
      }
    end

    def to_json
      json = {}
      %i[has_bom css file id].each do |name|
        value = instance_variable_get(:"@#{name}")
        json[name] = value if value
      end
      if @map
        json[:map] = @map.to_h
        json[:map].delete(:consumer_cache)
      end
      json
    end

    private

    def get_line_to_index
      return @line_to_index_cache if @line_to_index_cache

      lines = @css.split("\n")
      line_to_index = Array.new(lines.length)
      prev_index = 0

      lines.each_with_index do |_line, i|
        line_to_index[i] = prev_index
        prev_index += lines[i].length + 1
      end

      @line_to_index_cache = line_to_index
      line_to_index
    end

    def source_map_available?
      false # Source map support requires additional gem
    end

    def path_available?
      true
    end
  end
end
