# frozen_string_literal: true

begin
  require File.expand_path("../../../protocss/lib/protocss", __dir__)
  require File.expand_path("../../../protocss/lib/protocss/plugins", __dir__)
rescue LoadError
  raise
end

begin
  require "colorize"
rescue LoadError
  # Minimal no-op color helpers if colorize isn't available
  class String
    def colorize(*) = self
    def red = self
    def gray = self
  end
end

if defined?(Protocss::Root)
  Protocss::Root.register_processor(Protocss::Processor) if defined?(Protocss::Processor)
  Protocss::Root.register_lazy_result(Protocss::LazyResult) if defined?(Protocss::LazyResult)
end

if defined?(Protocss::Document)
  Protocss::Document.register_processor(Protocss::Processor) if defined?(Protocss::Processor)
  Protocss::Document.register_lazy_result(Protocss::LazyResult) if defined?(Protocss::LazyResult)
end

Protocss::Container.register_root(Protocss::Root) if defined?(Protocss::Container) && defined?(Protocss::Root)

module Typophic
  module Renderer
    class Protocss
      def initialize(plugins: nil, tailwind_config: nil)
      @plugins = Array(plugins).compact
      @plugins << ::Protocss::Plugins.tailwind(tailwind_config) if tailwind_config && ::Protocss.const_defined?(:Plugins) && ::Protocss::Plugins.respond_to?(:tailwind)
      @plugins << ::Protocss::Plugins.nested if ::Protocss.const_defined?(:Plugins) && ::Protocss::Plugins.respond_to?(:nested)
      @plugins << ::Protocss::Plugins.autoprefixer if ::Protocss.const_defined?(:Plugins) && ::Protocss::Plugins.respond_to?(:autoprefixer)
      end

      def compile(content, from: nil, to: nil)
        processor = ::Protocss.new(@plugins)
        result = processor.process(content.to_s, from: from, to: to)
        result.css
      rescue StandardError => e
        warn "  ❌ Protocss compilation error in #{from || '(inline)'}: #{e.message}"
        if e.backtrace
          warn "    #{e.backtrace.first}"
        end
        nil
      end
    end
  end
end
