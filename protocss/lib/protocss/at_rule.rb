# frozen_string_literal: true

module Protocss
  class AtRule < Container
    attr_accessor :name, :params

    def initialize(defaults = {})
      super(defaults)
      @type = 'atrule'
    end

    def append(*children)
      @nodes ||= []
      super(*children)
    end

    def prepend(*children)
      @nodes ||= []
      super(*children)
    end
  end
end

# Register after class definition
Protocss::Container.register_at_rule(Protocss::AtRule)
