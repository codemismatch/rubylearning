# frozen_string_literal: true

require_relative 'stringifier'

module Protocss
  module Stringify
    def self.call(node, builder = nil)
      str = Stringifier.new(builder)
      str.stringify(node)
    end

    def self.stringify(node, builder = nil)
      call(node, builder)
    end
  end
end
