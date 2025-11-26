# frozen_string_literal: true

require_relative 'stringify'

module Protocss
  class MapGenerator
    attr_accessor :stringify, :map_opts, :root, :opts

    def initialize(stringify, root, opts, css_string = nil)
      @stringify = stringify
      @map_opts = opts[:map] || {}
      @root = root
      @opts = opts
      @css = css_string
    end

    def generate
      clear_annotation
      if is_map?
        generate_map
      else
        result = ''
        @stringify.call(@root) { |i| result += i }
        [result]
      end
    end

    private

    def clear_annotation
      return if @map_opts[:annotation] == false

      if @root
        @root.nodes.reverse_each do |node|
          next unless node.type == 'comment'
          next unless node.text&.start_with?('# sourceMappingURL=')

          @root.remove_child(node)
        end
      elsif @css
        @css = @css.gsub(/\n*\/\*#[\S\s]*?\*\/$/m, '')
      end
    end

    def generate_map
      # Simplified map generation - full implementation would use source-map gem
      result = ''
      @stringify.call(@root) { |i| result += i }
      [result, nil]
    end

    def is_map?
      false # Source map support requires additional gem
    end
  end
end
