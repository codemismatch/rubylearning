# frozen_string_literal: true

module Protocss
  class Stringifier
    DEFAULT_RAW = {
      after: "\n",
      before_close: "\n",
      before_comment: "\n",
      before_decl: "\n",
      before_open: ' ',
      before_rule: "\n",
      colon: ': ',
      comment_left: ' ',
      comment_right: ' ',
      empty_body: '',
      indent: '    ',
      semicolon: false
    }.freeze

    attr_accessor :builder

    def initialize(builder = nil)
      @builder = builder || ->(str) { str }
      @result = ''
    end

    def stringify(node)
      case node.type
      when 'root'
        body(node)
      when 'rule'
        rule(node)
      when 'atrule'
        atrule(node)
      when 'decl'
        decl(node)
      when 'comment'
        comment(node)
      end
      @result
    end

    def atrule(node, semicolon = false)
      name = "@#{node.name}"
      params = node.params ? raw_value(node, 'params') : ''

      if node.raws[:after_name]
        name += node.raws[:after_name]
      elsif params
        name += ' '
      end

      if node.nodes
        block(node, name + params)
      else
        end_str = (node.raws[:between] || '') + (semicolon ? ';' : '')
        @result += name + params + end_str
      end
    end

    def block(node, start)
      between = raw(node, :between, :before_open)
      @result += start + between + '{'

      if node.nodes && !node.nodes.empty?
        body(node)
        after = raw(node, :after)
        @result += after if after
      else
        after = raw(node, :after, :empty_body)
        @result += after if after
      end

      @result += '}'
    end

    def body(node)
      last = node.nodes.length - 1
      last -= 1 while last > 0 && node.nodes[last].type == 'comment'

      semicolon = raw(node, :semicolon)
      node.nodes.each_with_index do |child, i|
        before = raw(child, :before)
        @result += before if before

        case child.type
        when 'rule'
          rule(child)
        when 'atrule'
          atrule(child)
        when 'decl'
          decl(child)
        when 'comment'
          comment(child)
        end

        if i < last || semicolon
          @result += semicolon ? ';' : ''
        end
      end
    end

    def comment(node)
      left = raw(node, :left, :comment_left)
      text = node.text
      right = raw(node, :right, :comment_right)
      @result += "/*#{left}#{text}#{right}*/"
    end

    def decl(node)
      between = raw(node, :between, :colon)
      string = node.prop + between + node.value.to_s
      if node.important
        string += node.raws[:important] || ' !important'
      end
      @result += string
    end

    def raw(node, prop, default_type = nil)
      return '' unless node.raws

      value = node.raws[prop] || node.raws[prop.to_s]
      return value if value

      default_type ||= prop
      DEFAULT_RAW[default_type] || ''
    end

    def raw_value(node, prop)
      value = node.raws[prop] || node.raws[prop.to_s]
      value || node.send(prop).to_s
    end

    def rule(node)
      selector = node.selector || ''
      block(node, selector)
    end
  end
end
