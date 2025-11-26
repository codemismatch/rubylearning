# frozen_string_literal: true

# Minimal colorize shim to avoid runtime dependency on the colorize gem.
class String
  def colorize(*) = self
  def red = self
  def gray = self
end
