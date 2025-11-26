# frozen_string_literal: true

require_relative 'input'
require_relative 'parser'

module Protocss
  module Parse
    def self.parse(css, opts = {})
      input = Input.new(css, opts)
      parser = Parser.new(input)
      begin
        parser.parse
      rescue CssSyntaxError => e
        if ENV['NODE_ENV'] != 'production' && opts[:from]
          if opts[:from].match?(/\.scss$/i)
            e.message += "\nYou tried to parse SCSS with the standard CSS parser; try again with the postcss-scss parser"
          elsif opts[:from].match?(/\.sass/i)
            e.message += "\nYou tried to parse Sass with the standard CSS parser; try again with the postcss-sass parser"
          elsif opts[:from].match?(/\.less$/i)
            e.message += "\nYou tried to parse Less with the standard CSS parser; try again with the postcss-less parser"
          end
        end
        raise e
      end
      parser.root
    end
  end
end

# Register after class definition
Protocss::Container.register_parse(Protocss::Parse)
