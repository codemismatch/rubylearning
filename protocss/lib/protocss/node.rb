# frozen_string_literal: true

require_relative 'css_syntax_error'
require_relative 'stringifier'
require_relative 'stringify'
require_relative 'symbols'

module Protocss
  class Node
    attr_accessor :raws, :parent, :source, :proxy_cache

    def proxy_of
      self
    end

    def initialize(defaults = {})
      @raws = {}
      instance_variable_set(:"@#{Symbols::IS_CLEAN}", false)
      instance_variable_set(:"@#{Symbols::MY}", true)

      defaults.each do |name, value|
        if name == :nodes || name == 'nodes'
          @nodes = []
          value.each do |node|
            if node.respond_to?(:clone)
              append(node.clone)
            else
              append(node)
            end
          end
        else
          instance_variable_set(:"@#{name}", value)
        end
      end
    end

    def add_to_error(error)
      error.postcss_node = self
      if error.respond_to?(:backtrace) && @source
        # Add source location to stack trace if available
        s = @source
        if s[:input] && s[:start]
          location = "#{s[:input].from}:#{s[:start][:line]}:#{s[:start][:column]}"
          error.set_backtrace(error.backtrace.map do |line|
            line.sub(/^/, "#{location} ")
          end)
        end
      end
      error
    end

    def after(add)
      @parent.insert_after(self, add) if @parent
      self
    end

    def assign(overrides = {})
      overrides.each { |name, value| instance_variable_set(:"@#{name}", value) }
      self
    end

    def before(add)
      @parent.insert_before(self, add) if @parent
      self
    end

    def clean_raws(keep_between = false)
      @raws.delete(:before)
      @raws.delete('before')
      @raws.delete(:after)
      @raws.delete('after')
      @raws.delete(:between) unless keep_between
    end

    def clone(overrides = {})
      cloned = clone_node(self)
      overrides.each { |name, value| cloned.instance_variable_set(:"@#{name}", value) }
      cloned
    end

    def clone_after(overrides = {})
      cloned = clone(overrides)
      @parent.insert_after(self, cloned) if @parent
      cloned
    end

    def clone_before(overrides = {})
      cloned = clone(overrides)
      @parent.insert_before(self, cloned) if @parent
      cloned
    end

    def error(message, opts = {})
      if @source
        range = range_by(opts)
        return @source[:input].error(
          message,
          { column: range[:start][:column], line: range[:start][:line] },
          { column: range[:end][:column], line: range[:end][:line] },
          opts
        )
      end
      CssSyntaxError.new(message)
    end

    def mark_clean
      instance_variable_set(:"@#{Symbols::IS_CLEAN}", true)
    end

    def mark_dirty
      unless instance_variable_get(:"@#{Symbols::IS_CLEAN}")
        return
      end
      instance_variable_set(:"@#{Symbols::IS_CLEAN}", false)
      next_node = self
      while (next_node = next_node.parent)
        next_node.instance_variable_set(:"@#{Symbols::IS_CLEAN}", false)
      end
    end

    def next
      return nil unless @parent
      index = @parent.index(self)
      @parent.nodes[index + 1] if index
    end

    def position_by(opts = {})
      pos = @source[:start] if @source
      return pos unless pos

      if opts[:index]
        pos = position_inside(opts[:index])
      elsif opts[:word]
        input_string = @source[:input].respond_to?(:document) ? @source[:input].document : @source[:input].css
        string_representation = input_string[source_offset(input_string, @source[:start])..source_offset(input_string, @source[:end])]
        index = string_representation.index(opts[:word])
        pos = position_inside(index) if index
      end
      pos
    end

    def position_inside(index)
      column = @source[:start][:column]
      line = @source[:start][:line]
      input_string = @source[:input].respond_to?(:document) ? @source[:input].document : @source[:input].css
      offset = source_offset(input_string, @source[:start])
      end_pos = offset + index

      (offset...end_pos).each do |i|
        if input_string[i] == "\n"
          column = 1
          line += 1
        else
          column += 1
        end
      end

      { column: column, line: line, offset: end_pos }
    end

    def prev
      return nil unless @parent
      index = @parent.index(self)
      @parent.nodes[index - 1] if index && index > 0
    end

    def range_by(opts = {})
      input_string = @source[:input].respond_to?(:document) ? @source[:input].document : @source[:input].css
      start = {
        column: @source[:start][:column],
        line: @source[:start][:line],
        offset: source_offset(input_string, @source[:start])
      }

      end_pos = if @source[:end]
                  if @source[:end][:offset].is_a?(Numeric)
                    {
                      column: @source[:end][:column] + 1,
                      line: @source[:end][:line],
                      offset: @source[:end][:offset]
                    }
                  else
                    {
                      column: @source[:end][:column] + 1,
                      line: @source[:end][:line],
                      offset: source_offset(input_string, @source[:end]) + 1
                    }
                  end
                else
                  {
                    column: start[:column] + 1,
                    line: start[:line],
                    offset: start[:offset] + 1
                  }
                end

      if opts[:word]
        string_representation = input_string[source_offset(input_string, @source[:start])..source_offset(input_string, @source[:end])]
        index = string_representation.index(opts[:word])
        if index
          start = position_inside(index)
          end_pos = position_inside(index + opts[:word].length)
        end
      else
        if opts[:start]
          start = {
            column: opts[:start][:column],
            line: opts[:start][:line],
            offset: source_offset(input_string, opts[:start])
          }
        elsif opts[:index]
          start = position_inside(opts[:index])
        end

        if opts[:end]
          end_pos = {
            column: opts[:end][:column],
            line: opts[:end][:line],
            offset: source_offset(input_string, opts[:end])
          }
        elsif opts[:end_index].is_a?(Numeric)
          end_pos = position_inside(opts[:end_index])
        elsif opts[:index]
          end_pos = position_inside(opts[:index] + 1)
        end
      end

      if end_pos[:line] < start[:line] || (end_pos[:line] == start[:line] && end_pos[:column] <= start[:column])
        end_pos = {
          column: start[:column] + 1,
          line: start[:line],
          offset: start[:offset] + 1
        }
      end

      { end: end_pos, start: start }
    end

    def raw(prop, default_type = nil)
      str = Stringifier.new
      str.raw(self, prop, default_type)
    end

    def remove
      @parent.remove_child(self) if @parent
      @parent = nil
      self
    end

    def replace_with(*nodes)
      return self unless @parent

      bookmark = self
      found_self = false
      nodes.each do |node|
        if node == self
          found_self = true
        elsif found_self
          @parent.insert_after(bookmark, node)
          bookmark = node
        else
          @parent.insert_before(bookmark, node)
        end
      end

      remove unless found_self
      self
    end

    def root
      result = self
      while result.parent && result.parent.type != 'document'
        result = result.parent
      end
      result
    end

    def to_json(_ = nil, inputs = nil)
      fixed = {}
      emit_inputs = inputs.nil?
      inputs ||= {}
      inputs_next_index = 0

      instance_variables.each do |var|
        name = var.to_s[1..-1].to_sym
        next if name == :parent || name == :proxy_cache

        value = instance_variable_get(var)

        if value.is_a?(Array)
          fixed[name] = value.map do |i|
            if i.is_a?(Hash) && i.respond_to?(:to_json)
              i.to_json(nil, inputs)
            else
              i
            end
          end
        elsif value.respond_to?(:to_json)
          fixed[name] = value.to_json(nil, inputs)
        elsif name == :source
          next unless value
          input_id = inputs[value[:input]]
          unless input_id
            input_id = inputs_next_index
            inputs[value[:input]] = inputs_next_index
            inputs_next_index += 1
          end
          fixed[name] = {
            end: value[:end],
            input_id: input_id,
            start: value[:start]
          }
        else
          fixed[name] = value
        end
      end

      if emit_inputs
        fixed[:inputs] = inputs.keys.map(&:to_json)
      end

      fixed
    end

    def to_proxy
      @proxy_cache ||= self
      @proxy_cache
    end

    def to_s(stringifier = Stringify)
      stringifier = stringifier.stringify if stringifier.respond_to?(:stringify)
      result = ''
      stringifier.call(self) { |i| result += i }
      result
    end

    def warn(result, text, opts = {})
      data = { node: self }.merge(opts)
      result.warn(text, data)
    end

    private

    def clone_node(obj, parent = nil)
      cloned = obj.class.new

      obj.instance_variables.each do |var|
        next if var == :@proxy_cache

        value = obj.instance_variable_get(var)
        name = var.to_s[1..-1].to_sym

        if name == :parent && value.is_a?(Hash)
          cloned.instance_variable_set(var, parent) if parent
        elsif name == :source
          cloned.instance_variable_set(var, value)
        elsif value.is_a?(Array)
          cloned.instance_variable_set(var, value.map { |j| clone_node(j, cloned) })
        elsif value.is_a?(Hash) && value != nil
          cloned.instance_variable_set(var, clone_node(value))
        else
          cloned.instance_variable_set(var, value)
        end
      end

      cloned
    end

    def source_offset(input_css, position)
      return position[:offset] if position && position[:offset]

      column = 1
      line = 1
      offset = 0

      input_css.length.times do |i|
        if line == position[:line] && column == position[:column]
          offset = i
          break
        end

        if input_css[i] == "\n"
          column = 1
          line += 1
        else
          column += 1
        end
      end

      offset
    end
  end
end
