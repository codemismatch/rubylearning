# frozen_string_literal: true

module Protocss
  class Comment < Node
    attr_accessor :text

    def initialize(defaults = {})
      super(defaults)
      @type = 'comment'
    end
  end
end
