# frozen_string_literal: true

require_relative 'lazy_result'
require_relative 'no_work_result'

module Protocss
  class Processor
    attr_accessor :version, :plugins

    def initialize(plugins = [])
      @version = '0.1.0'
      @plugins = normalize(plugins)
    end

    def normalize(plugins)
      normalized = []
      plugins.each do |i|
        if i.respond_to?(:postcss) && i.postcss == true
          i = i.call
        elsif i.respond_to?(:postcss)
          i = i.postcss
        elsif i.respond_to?(:Once) || i.respond_to?(:Rule) || i.respond_to?(:Declaration)
          normalized << i
          next
        end

        if i.is_a?(Hash) && i[:plugins].is_a?(Array)
          normalized.concat(i[:plugins])
        elsif i.is_a?(Hash) && (i[:postcss_plugin] || i['postcss_plugin'])
          normalized << i
        elsif i.is_a?(Proc) || i.respond_to?(:call)
          normalized << i
        elsif i.is_a?(Hash) && (i[:parse] || i[:stringify])
          raise StandardError, 'PostCSS syntaxes cannot be used as plugins' if ENV['NODE_ENV'] != 'production'
        else
          raise StandardError, "#{i} is not a PostCSS plugin"
        end
      end
      normalized
    end

    def process(css, opts = {})
      if @plugins.empty? && !opts[:parser] && !opts[:stringifier] && !opts[:syntax]
        NoWorkResult.new(self, css, opts)
      else
        LazyResult.new(self, css, opts)
      end
    end

    def use(plugin)
      @plugins = @plugins.concat(normalize([plugin]))
      self
    end
  end
end
