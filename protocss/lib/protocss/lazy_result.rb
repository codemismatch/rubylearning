# frozen_string_literal: true

require_relative 'result'
require_relative 'parse'
require_relative 'stringify'
require_relative 'map_generator'
require_relative 'symbols'

module Protocss
  class LazyResult
    TYPE_TO_CLASS_NAME = {
      'atrule' => 'AtRule',
      'comment' => 'Comment',
      'decl' => 'Declaration',
      'document' => 'Document',
      'root' => 'Root',
      'rule' => 'Rule'
    }.freeze

    PLUGIN_PROPS = {
      'AtRule' => true,
      'AtRuleExit' => true,
      'Comment' => true,
      'CommentExit' => true,
      'Declaration' => true,
      'DeclarationExit' => true,
      'Document' => true,
      'DocumentExit' => true,
      'Once' => true,
      'OnceExit' => true,
      'postcss_plugin' => true,
      'prepare' => true,
      'Root' => true,
      'RootExit' => true,
      'Rule' => true,
      'RuleExit' => true
    }.freeze

    NOT_VISITORS = {
      'Once' => true,
      'postcss_plugin' => true,
      'prepare' => true
    }.freeze

    CHILDREN = 0

    attr_accessor :stringified, :processed, :result, :helpers, :plugins, :error, :processing, :listeners, :has_listener

    def content
      stringify.content
    end

    def css
      stringify.css
    end

    def map
      stringify.map
    end

    def messages
      sync.messages
    end

    def opts
      @result.opts
    end

    def processor
      @result.processor
    end

    def root
      sync.root
    end

    def initialize(processor, css, opts = {})
      @stringified = false
      @processed = false

      root = nil
      if css.is_a?(Hash) && (css[:type] == 'root' || css['type'] == 'root' || css[:type] == 'document' || css['type'] == 'document')
        root = clean_marks(css)
      elsif css.is_a?(LazyResult) || css.is_a?(Result)
        root = clean_marks(css.root)
        if css.map
          opts[:map] ||= {}
          opts[:map][:inline] = false unless opts[:map][:inline]
          opts[:map][:prev] = css.map
        end
      else
        parser = Parse
        parser = opts[:syntax][:parse] if opts[:syntax] && opts[:syntax][:parse]
        parser = opts[:parser] if opts[:parser]
        if parser.respond_to?(:parse) && !parser.respond_to?(:call)
          parser = parser.method(:parse)
        end

        begin
          root = parser.call(css, opts)
        rescue StandardError => error
          @processed = true
          @error = error
        end

        Container.rebuild(root) if root && !root.instance_variable_get(:"@#{Symbols::MY}")
      end

      @result = Result.new(processor, root, opts)
      @helpers = { postcss: Protocss, result: @result }
      @plugins = processor.plugins.map do |plugin|
        if plugin.is_a?(Hash) && plugin[:prepare]
          plugin.merge(plugin[:prepare].call(@result))
        else
          plugin
        end
      end
    end

    def sync
      raise @error if @error
      return @result if @processed

      @processed = true
      raise get_async_error if @processing

      @plugins.each do |plugin|
        promise = run_on_root(plugin)
        raise get_async_error if defined?(Promise) && (promise.is_a?(Promise) || promise.respond_to?(:then))
      end

      prepare_visitors
      if @has_listener
        root = @result.root
        while !root.instance_variable_get(:"@#{Symbols::IS_CLEAN}")
          root.instance_variable_set(:"@#{Symbols::IS_CLEAN}", true)
          walk_sync(root)
        end
        if @listeners['OnceExit']
          if root.type == 'document'
            root.nodes.each { |sub_root| visit_sync(@listeners['OnceExit'], sub_root) }
          else
            visit_sync(@listeners['OnceExit'], root)
          end
        end
      end

      @result
    end

    def stringify
      raise @error if @error
      return @result if @stringified

      @stringified = true
      sync

      opts = @result.opts
      str = Stringify
      str = opts[:syntax][:stringify] if opts[:syntax] && opts[:syntax][:stringify]
      str = opts[:stringifier] if opts[:stringifier]
      str = str.stringify if str.respond_to?(:stringify)

      map_gen = MapGenerator.new(str, @result.root, @result.opts)
      data = map_gen.generate
      @result.css = data[0]
      @result.map = data[1]

      @result
    end

    def to_s
      css
    end

    def warnings
      sync.warnings
    end

    class << self
      attr_accessor :postcss_module

      def register_postcss(dependant)
        @postcss_module = dependant
      end
    end

    private

    def clean_marks(node)
      node.instance_variable_set(:"@#{Symbols::IS_CLEAN}", false)
      node.nodes&.each { |i| clean_marks(i) }
      node
    end

    def get_async_error
      StandardError.new('Use process(css).then(cb) to work with async plugins')
    end

    def get_events(node)
      key = false
      type = TYPE_TO_CLASS_NAME[node.type]
      if node.type == 'decl'
        key = node.prop&.downcase
      elsif node.type == 'atrule'
        key = node.name&.downcase
      end

      if key && node.respond_to?(:append)
        [type, "#{type}-#{key}", CHILDREN, "#{type}Exit", "#{type}Exit-#{key}"]
      elsif key
        [type, "#{type}-#{key}", "#{type}Exit", "#{type}Exit-#{key}"]
      elsif node.respond_to?(:append)
        [type, CHILDREN, "#{type}Exit"]
      else
        [type, "#{type}Exit"]
      end
    end

    def handle_error(error, node = nil)
      plugin = @result.last_plugin
      begin
        node.add_to_error(error) if node
        @error = error
        if error.is_a?(CssSyntaxError) && !error.plugin
          error.plugin = plugin[:postcss_plugin] if plugin.is_a?(Hash) && plugin[:postcss_plugin]
          error.set_message
        end
      rescue StandardError => e
        warn e
      end
      error
    end

    def prepare_visitors
      @listeners = {}
      @plugins.each do |plugin|
        next unless plugin.is_a?(Hash)

        plugin.each do |event, handler|
          next unless PLUGIN_PROPS[event.to_s]
          next if NOT_VISITORS[event.to_s]

          if handler.is_a?(Hash)
            handler.each do |filter, callback|
              event_name = filter == '*' ? event : "#{event}-#{filter.to_s.downcase}"
              (@listeners[event_name] ||= []) << [plugin, callback]
            end
          elsif handler.respond_to?(:call)
            (@listeners[event.to_s] ||= []) << [plugin, handler]
          end
        end
      end
      @has_listener = !@listeners.empty?
    end

    def run_on_root(plugin)
      @result.last_plugin = plugin
      begin
        if plugin.is_a?(Hash) && plugin[:Once]
          if @result.root.type == 'document'
            @result.root.nodes.map { |root| plugin[:Once].call(root, @helpers) }
          else
            plugin[:Once].call(@result.root, @helpers)
          end
        elsif plugin.respond_to?(:call)
          plugin.call(@result.root, @result)
        end
      rescue StandardError => error
        raise handle_error(error)
      end
    end

    def visit_sync(visitors, node)
      visitors.each do |plugin, visitor|
        @result.last_plugin = plugin
        begin
          promise = visitor.call(node.to_proxy, @helpers)
          return true if node.type != 'root' && node.type != 'document' && !node.parent
          raise get_async_error if promise.is_a?(Promise) || promise.respond_to?(:then)
        rescue StandardError => e
          raise handle_error(e, node.proxy_of)
        end
      end
    end

    def walk_sync(node)
      node.instance_variable_set(:"@#{Symbols::IS_CLEAN}", true)
      events = get_events(node)
      events.each do |event|
        if event == CHILDREN
          node.nodes&.each do |child|
            walk_sync(child) unless child.instance_variable_get(:"@#{Symbols::IS_CLEAN}")
          end
        else
          visitors = @listeners[event]
          return if visit_sync(visitors, node.to_proxy) if visitors
        end
      end
    end
  end
end

# Note: Registration happens in root.rb and document.rb
