# frozen_string_literal: true

module Protocss
  class Declaration < Node
    attr_accessor :prop, :value, :important

    def variable
      @prop&.start_with?('--') || @prop&.[](0) == '$'
    end

    def initialize(defaults = {})
      if defaults && defaults[:value] && !defaults[:value].is_a?(String)
        defaults = defaults.merge(value: defaults[:value].to_s)
      end
      super(defaults)
      @type = 'decl'
    end
  end
end
