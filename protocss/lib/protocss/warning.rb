# frozen_string_literal: true

module Protocss
  class Warning
    attr_accessor :type, :text, :line, :column, :end_line, :end_column, :node, :plugin, :index, :word

    def initialize(text, opts = {})
      @type = 'warning'
      @text = text

      if opts[:node] && opts[:node].source
        range = opts[:node].range_by(opts)
        @line = range[:start][:line]
        @column = range[:start][:column]
        @end_line = range[:end][:line]
        @end_column = range[:end][:column]
      end

      opts.each { |key, value| instance_variable_set(:"@#{key}", value) }
    end

    def to_s
      if @node
        return @node.error(@text, {
          index: @index,
          plugin: @plugin,
          word: @word
        }).message
      end

      return "#{@plugin}: #{@text}" if @plugin

      @text
    end
  end
end
