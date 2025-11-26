# frozen_string_literal: true

# Rails integration for Protocss Sprockets processor
if defined?(Rails)
  module Protocss
    module Sprockets
      class Railtie < ::Rails::Railtie
        initializer 'protocss.sprockets', after: 'sprockets.environment', group: :all do |app|
          next unless app.assets

          # Register Protocss processor
          app.assets.register_mime_type 'text/css', extensions: ['.css']
          app.assets.register_transformer 'text/css', 'text/css', Processor

          Rails.logger.info 'Protocss Sprockets processor registered' if Rails.logger
        end
      end
    end
  end
end
