# frozen_string_literal: true

require_relative 'protocss/version'
require_relative 'protocss/symbols'
require_relative 'protocss/css_syntax_error'
require_relative 'protocss/node'
require_relative 'protocss/container'
require_relative 'protocss/declaration'
require_relative 'protocss/comment'
require_relative 'protocss/rule'
require_relative 'protocss/at_rule'
require_relative 'protocss/input'
require_relative 'protocss/warning'
require_relative 'protocss/result'
require_relative 'protocss/lazy_result'
require_relative 'protocss/processor'
require_relative 'protocss/root'
require_relative 'protocss/document'
require_relative 'protocss/parse'
require_relative 'protocss/stringify'
require_relative 'protocss/list'
require_relative 'protocss/from_json'
require_relative 'protocss/plugins'

module Protocss
  def self.new(*plugins)
    plugins = plugins[0] if plugins.length == 1 && plugins[0].is_a?(Array)
    Processor.new(plugins)
  end

  def self.parse(css, opts = {})
    Parse.parse(css, opts)
  end

  def self.stringify
    Stringify
  end

  def self.from_json(json, opts = {})
    FromJson.from_json(json, opts)
  end

  def self.list
    List
  end

  def self.comment(defaults = {})
    Comment.new(defaults)
  end

  def self.at_rule(defaults = {})
    AtRule.new(defaults)
  end

  def self.decl(defaults = {})
    Declaration.new(defaults)
  end

  def self.rule(defaults = {})
    Rule.new(defaults)
  end

  def self.root(defaults = {})
    Root.new(defaults)
  end

  def self.document(defaults = {})
    Document.new(defaults)
  end
end

# Note: Dependencies are registered in their respective files
