# frozen_string_literal: true

require 'colorize'

module Protocss
  class CssSyntaxError < StandardError
    attr_accessor :reason, :file, :source, :plugin, :line, :column, :end_line, :end_column, :input

    def initialize(message, line = nil, column = nil, source = nil, file = nil, plugin = nil)
      super(message)
      @reason = message
      @file = file
      @source = source
      @plugin = plugin

      if line && column
        if line.is_a?(Numeric)
          @line = line
          @column = column
        else
          @line = line[:line] || line['line']
          @column = line[:column] || line['column']
          @end_line = column[:line] || column['line']
          @end_column = column[:column] || column['column']
        end
      end

      set_message
    end

    def set_message
      self.message = ''
      self.message += "#{@plugin}: " if @plugin
      self.message += @file || '<css input>'
      self.message += ":#{@line}:#{@column}" if @line
      self.message += ": #{@reason}"
    end

    def show_source_code(color: true)
      return '' unless @source

      css = @source
      lines = css.split(/\r?\n/)
      start = [@line - 3, 0].max
      end_pos = [@line + 2, lines.length].min
      max_width = end_pos.to_s.length

      lines[start...end_pos].map.with_index do |line, index|
        number = start + 1 + index
        gutter = " #{number.to_s.rjust(max_width)} | "

        if number == @line
          if line.length > 160
            padding = 20
            sub_line_start = [0, @column - padding].max
            sub_line_end = [
              @column + padding,
              (@end_column || @column) + padding
            ].max
            sub_line = line[sub_line_start...sub_line_end]

            spacing = (' ' * gutter.length) +
                      line[0...[@column - 1, padding - 1].min].gsub(/[^\t]/, ' ')

            if color
              "> #{gutter}#{sub_line}\n #{spacing}^".red
            else
              "> #{gutter}#{sub_line}\n #{spacing}^"
            end
          else
            spacing = (' ' * gutter.length) +
                      line[0...(@column - 1)].gsub(/[^\t]/, ' ')

            if color
              "> #{gutter}#{line}\n #{spacing}^".red
            else
              "> #{gutter}#{line}\n #{spacing}^"
            end
          end
        else
          if color
            "  #{gutter}#{line}".gray
          else
            "  #{gutter}#{line}"
          end
        end
      end.join("\n")
    end

    def to_s
      code = show_source_code
      code = "\n\n#{code}\n" if code && !code.empty?
      "#{self.class.name}: #{message}#{code}"
    end
  end
end
