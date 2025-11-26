# frozen_string_literal: true

module Protocss
  class Result
    attr_accessor :processor, :messages, :root, :opts, :css, :map, :last_plugin

    def content
      @css
    end

    def initialize(processor, root, opts = {})
      @processor = processor
      @messages = []
      @root = root
      @opts = opts
      @css = ''
      @map = nil
      @last_plugin = nil
    end

    def to_s
      @css
    end

    def warn(text, opts = {})
      opts[:plugin] ||= @last_plugin&.postcss_plugin if @last_plugin&.respond_to?(:postcss_plugin)

      warning = Warning.new(text, opts)
      @messages << warning
      warning
    end

    def warnings
      @messages.select { |m| m.type == 'warning' }
    end
  end
end
