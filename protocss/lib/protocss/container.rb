# frozen_string_literal: true

require_relative 'node'
require_relative 'symbols'

module Protocss
  class Container < Node
    attr_accessor :nodes, :indexes, :last_each

    def first
      @nodes&.[](0)
    end

    def last
      @nodes&.[](-1)
    end

    def append(*children)
      children.each do |child|
        nodes = normalize(child, @last)
        nodes.each { |node| @nodes << node }
      end

      mark_dirty
      self
    end

    def clean_raws(keep_between = false)
      super(keep_between)
      @nodes&.each { |node| node.clean_raws(keep_between) }
    end

    def each(callback = nil)
      return enum_for(:each) unless callback
      return nil unless @nodes

      iterator = get_iterator

      index = nil
      result = nil
      while @indexes[iterator] < @nodes.length
        index = @indexes[iterator]
        result = callback.call(@nodes[index], index)
        break if result == false

        @indexes[iterator] += 1
      end

      @indexes.delete(iterator)
      result
    end

    def every(condition)
      @nodes&.all?(&condition)
    end

    def get_iterator
      @last_each ||= 0
      @indexes ||= {}

      @last_each += 1
      iterator = @last_each
      @indexes[iterator] = 0

      iterator
    end

    def index(child)
      return child if child.is_a?(Numeric)
      child = child.proxy_of if child.respond_to?(:proxy_of)
      @nodes&.index(child)
    end

    def insert_after(exist, add)
      exist_index = index(exist)
      nodes = normalize(add, @nodes[exist_index]).reverse
      exist_index = index(exist)
      nodes.each { |node| @nodes.insert(exist_index + 1, node) }

      @indexes&.each do |id, idx|
        @indexes[id] = idx + nodes.length if exist_index < idx
      end

      mark_dirty
      self
    end

    def insert_before(exist, add)
      exist_index = index(exist)
      type = exist_index == 0 ? :prepend : false
      nodes = normalize(add, @nodes[exist_index], type).reverse
      exist_index = index(exist)
      nodes.each { |node| @nodes.insert(exist_index, node) }

      @indexes&.each do |id, idx|
        @indexes[id] = idx + nodes.length if exist_index <= idx
      end

      mark_dirty
      self
    end

    def normalize(nodes, sample = nil)
      if nodes.is_a?(String)
        nodes = clean_source(Parse.parse(nodes).nodes)
      elsif nodes.nil?
        nodes = []
      elsif nodes.is_a?(Array)
        nodes = nodes.dup
        nodes.each { |i| i.parent.remove_child(i, ignore: true) if i.parent }
      elsif nodes.is_a?(Protocss::Node)
        nodes = [nodes]
      elsif nodes.respond_to?(:type) && nodes.type == 'root' && @type != 'document'
        nodes = nodes.nodes.dup
        nodes.each { |i| i.parent.remove_child(i, ignore: true) if i.parent }
      elsif nodes.respond_to?(:type) && nodes.type
        nodes = [nodes]
      elsif (nodes.respond_to?(:[]) && (nodes[:prop] || nodes['prop'])) || nodes.respond_to?(:prop)
        prop = nodes[:prop] || nodes['prop'] if nodes.respond_to?(:[])
        prop ||= nodes.prop if nodes.respond_to?(:prop)
        value = nodes[:value] || nodes['value'] if nodes.respond_to?(:[])
        value ||= nodes.value if nodes.respond_to?(:value)
        
        # Guard: Only create Declaration if prop is present
        if prop && !prop.to_s.strip.empty?
          value ||= ''
          value = value.to_s unless value.is_a?(String)
          nodes = [Declaration.new(nodes)]
        else
          # Skip Declaration creation if prop is missing/empty
          nodes = []
        end
      elsif (nodes.respond_to?(:[]) && (nodes[:selector] || nodes['selector'] || nodes[:selectors] || nodes['selectors'])) ||
            nodes.respond_to?(:selector) || nodes.respond_to?(:selectors)
        nodes = [Rule.new(nodes)]
      elsif (nodes.respond_to?(:[]) && (nodes[:name] || nodes['name'])) || nodes.respond_to?(:name)
        nodes = [AtRule.new(nodes)]
      elsif (nodes.respond_to?(:[]) && (nodes[:text] || nodes['text'])) || nodes.respond_to?(:text)
        nodes = [nodes.is_a?(Comment) ? nodes : Comment.new(nodes)]
      else
        raise StandardError, 'Unknown node type in node creation'
      end

      processed = nodes.map do |i|
        Container.rebuild(i) unless i.instance_variable_get(:"@#{Symbols::MY}")
        i = i.proxy_of if i.respond_to?(:proxy_of)
        i.parent.remove_child(i) if i.parent
        mark_tree_dirty(i) if i.instance_variable_get(:"@#{Symbols::IS_CLEAN}")

        i.raws ||= {}
        if i.raws[:before].nil? && i.raws['before'].nil?
          if sample && (sample.raws[:before] || sample.raws['before'])
            before = sample.raws[:before] || sample.raws['before']
            i.raws[:before] = before.gsub(/\S/, '')
          end
        end
        i.parent = self
        i
      end

      processed
    end

    def prepend(*children)
      children.reverse.each do |child|
        nodes = normalize(child, @first, :prepend).reverse
        nodes.each { |node| @nodes.unshift(node) }
        @indexes&.each { |id, _| @indexes[id] += nodes.length }
      end

      mark_dirty
      self
    end

    def push(child)
      child.parent = self
      @nodes << child
      self
    end

    def remove_all
      @nodes&.each { |node| node.parent = nil }
      @nodes = []

      mark_dirty
      self
    end

    def remove_child(child, ignore: false)
      child_index = index(child)
      @nodes[child_index].parent = nil if @nodes[child_index]
      @nodes.delete_at(child_index)

      @indexes&.each do |id, idx|
        @indexes[id] = idx - 1 if idx >= child_index
      end

      mark_dirty
      self
    end

    def replace_values(pattern, opts = {}, callback = nil)
      if callback.nil?
        callback = opts
        opts = {}
      end

      walk_decls do |decl|
        next if opts[:props] && !opts[:props].include?(decl.prop)
        next if opts[:fast] && !decl.value.include?(opts[:fast])

        decl.value = decl.value.gsub(pattern, &callback)
      end

      mark_dirty
      self
    end

    def some(condition)
      @nodes&.any?(&condition)
    end

    def walk(callback)
      each do |child, i|
        result = nil
        begin
          result = callback.call(child, i)
        rescue StandardError => e
          raise child.add_to_error(e)
        end
        if result != false && child.respond_to?(:walk)
          result = child.walk(callback)
        end
        result
      end
    end

    def walk_at_rules(name = nil, callback = nil)
      if callback.nil?
        callback = name
        return walk do |child, i|
          callback.call(child, i) if child.type == 'atrule'
        end
      end

      if name.is_a?(Regexp)
        return walk do |child, i|
          callback.call(child, i) if child.type == 'atrule' && name.match?(child.name)
        end
      end

      walk do |child, i|
        callback.call(child, i) if child.type == 'atrule' && child.name == name
      end
    end

    def walk_comments(callback)
      walk do |child, i|
        callback.call(child, i) if child.type == 'comment'
      end
    end

    def walk_decls(prop = nil, callback = nil)
      if callback.nil?
        callback = prop
        return walk do |child, i|
          callback.call(child, i) if child.type == 'decl'
        end
      end

      if prop.is_a?(Regexp)
        return walk do |child, i|
          callback.call(child, i) if child.type == 'decl' && prop.match?(child.prop)
        end
      end

      walk do |child, i|
        callback.call(child, i) if child.type == 'decl' && child.prop == prop
      end
    end

    def walk_rules(selector = nil, callback = nil)
      if callback.nil?
        callback = selector
        return walk do |child, i|
          callback.call(child, i) if child.type == 'rule'
        end
      end

      if selector.is_a?(Regexp)
        return walk do |child, i|
          callback.call(child, i) if child.type == 'rule' && selector.match?(child.selector)
        end
      end

      walk do |child, i|
        callback.call(child, i) if child.type == 'rule' && child.selector == selector
      end
    end

    class << self
      attr_accessor :parse_func, :rule_class, :at_rule_class, :root_class

      def register_parse(dependant)
        @parse_func = dependant
      end

      def register_rule(dependant)
        @rule_class = dependant
      end

      def register_at_rule(dependant)
        @at_rule_class = dependant
      end

      def register_root(dependant)
        @root_class = dependant
      end

      def rebuild(node)
        case node.type
        when 'atrule'
          node.extend(AtRule) unless node.is_a?(AtRule)
        when 'rule'
          node.extend(Rule) unless node.is_a?(Rule)
        when 'decl'
          node.extend(Declaration) unless node.is_a?(Declaration)
        when 'comment'
          node.extend(Comment) unless node.is_a?(Comment)
        when 'root'
          node.extend(Root) unless node.is_a?(Root)
        end

        node.instance_variable_set(:"@#{Symbols::MY}", true)

        node.nodes&.each { |child| rebuild(child) }
      end
    end

    private

    def clean_source(nodes)
      nodes.map do |i|
        i.nodes = clean_source(i.nodes) if i.nodes
        i.instance_variable_set(:@source, nil)
        i
      end
    end

    def mark_tree_dirty(node)
      node.instance_variable_set(:"@#{Symbols::IS_CLEAN}", false)
      node.nodes&.each { |i| mark_tree_dirty(i) }
    end
  end
end

# Register after class definition
Protocss::Container.register_root(Protocss::Root) if defined?(Protocss::Root)
