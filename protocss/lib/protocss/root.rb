# frozen_string_literal: true

module Protocss
  class Root < Container
    def initialize(defaults = {})
      super(defaults)
      @type = 'root'
      @nodes ||= []
    end

    def normalize(child, sample = nil, type = nil)
      nodes = super(child)

      if sample
        if type == :prepend
          if @nodes.length > 1
            sample.raws[:before] = @nodes[1].raws[:before]
          else
            sample.raws.delete(:before)
          end
        elsif @first != sample
          nodes.each do |node|
            node.raws[:before] = sample.raws[:before]
          end
        end
      end

      nodes
    end

    def remove_child(child, ignore = false)
      index = index(child)

      if !ignore && index == 0 && @nodes.length > 1
        @nodes[1].raws[:before] = @nodes[index].raws[:before]
      end

      super(child)
    end

    def to_result(opts = {})
      lazy = Root.lazy_result_class.new(Root.processor_class.new([]), self, opts)
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
Protocss::Root.register_processor(Protocss::Processor) if defined?(Protocss::Processor)
Protocss::Root.register_lazy_result(Protocss::LazyResult) if defined?(Protocss::LazyResult)
Protocss::Container.register_root(Protocss::Root) if defined?(Protocss::Container)
