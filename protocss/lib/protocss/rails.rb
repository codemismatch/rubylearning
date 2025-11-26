# frozen_string_literal: true

require_relative 'sprockets/railtie' if defined?(Rails)

# Rails engine for automatic integration
if defined?(Rails)
  module Protocss
    module Rails
      class Engine < ::Rails::Engine
        # Railtie handles the registration
        # This engine ensures the files are loaded
      end
    end
  end
end
