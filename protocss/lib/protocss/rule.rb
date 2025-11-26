# frozen_string_literal: true

require_relative 'list'

module Protocss
  class Rule < Container
    attr_accessor :selector

    def selectors
      List.comma(@selector)
    end

    def selectors=(values)
      match = @selector&.match(/,\s*/)
      sep = match ? match[0] : ',' + raw(:between, :before_open)
      @selector = values.join(sep)
    end

    def initialize(defaults = {})
      super(defaults)
      @type = 'rule'
      @nodes ||= []
    end
  end
end

# Register after class definition
Protocss::Container.register_rule(Protocss::Rule)
