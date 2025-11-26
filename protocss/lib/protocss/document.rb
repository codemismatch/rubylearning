# frozen_string_literal: true

module Protocss
  class Document < Container
    def initialize(defaults = {})
      super({ type: 'document' }.merge(defaults))
      @nodes ||= []
    end

    def to_result(opts = {})
      lazy = Document.lazy_result_class.new(Document.processor_class.new([]), self, opts)
      lazy.stringify
    end

    class << self
      attr_accessor :lazy_result_class, :processor_class

      def register_lazy_result(dependant)
        @lazy_result_class = dependant
      end

      def register_processor(dependant)
        @processor_class = dependant
      end
    end
  end
end

# Register after class definition
Protocss::Document.register_processor(Protocss::Processor) if defined?(Protocss::Processor)
Protocss::Document.register_lazy_result(Protocss::LazyResult) if defined?(Protocss::LazyResult)
