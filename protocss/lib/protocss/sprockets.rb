# frozen_string_literal: true

require_relative 'sprockets/processor'

# Auto-register processor when required
if defined?(::Sprockets)
  require 'protocss/sprockets/processor'
end
