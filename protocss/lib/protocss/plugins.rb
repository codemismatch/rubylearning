# frozen_string_literal: true

require_relative 'plugins/autoprefixer'
require_relative 'plugins/nested'

module Protocss
  module Plugins
    # Convenience method to create Autoprefixer plugin
    def self.autoprefixer(opts = {})
      Autoprefixer.new(opts).to_plugin
    end

    # Convenience method to create Nested plugin
    def self.nested(opts = {})
      Nested.new(opts).to_plugin
    end
  end
end
