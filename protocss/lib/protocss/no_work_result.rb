# frozen_string_literal: true

module Protocss
  class NoWorkResult
    attr_accessor :processor, :css, :opts, :root, :messages, :map

    def initialize(processor, css, opts = {})
      @processor = processor
      @css = css.is_a?(String) ? css : css.to_s
      @opts = opts
      @root = nil
      @messages = []
      @map = nil
    end

    def content
      @css
    end

    def to_s
      @css
    end

    def warnings
      []
    end
  end
end
