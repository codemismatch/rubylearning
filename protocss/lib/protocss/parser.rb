# frozen_string_literal: true

require_relative 'tokenize'
require_relative 'root'
require_relative 'rule'
require_relative 'at_rule'
require_relative 'declaration'
require_relative 'comment'

module Protocss
  class Parser
    attr_accessor :input, :root, :current, :spaces, :semicolon, :tokenizer

    SAFE_COMMENT_NEIGHBOR = { empty: true, space: true }.freeze

    def initialize(input)
      @input = input
      @root = Root.new
      @current = @root
      @spaces = ''
      @semicolon = false
      create_tokenizer
      @root.source = { input: input, start: { column: 1, line: 1, offset: 0 } }
    end

    def parse
      token = nil
      loop do
        token = @tokenizer[:next_token].call
        break unless token

        case token[0]
        when 'space'
          @spaces += token[1]
        when ';'
          @semicolon = true
          end_file
        when '}'
          end_file
        when 'comment'
          comment(token)
        when 'at-word'
          @spaces = ''
          atrule(token)
        when '{'
          empty_rule(token)
        else
          @spaces = ''
          word(token)
        end
      end
      @root
    end

    private

    def create_tokenizer
      @tokenizer = Tokenize.tokenizer(@input)
    end

    def atrule(token)
      node = AtRule.new
      node.name = token[1][1..-1]
      init(node, token[2])

      type = nil
      prev = nil
      shift = nil
      last = false
      open = false
      params = []
      brackets = []

      until @tokenizer[:end_of_file].call
        token = @tokenizer[:next_token].call
        break unless token

        type = token[0]

        if type == '(' || type == '['
          brackets << (type == '(' ? ')' : ']')
        elsif type == '{' && !brackets.empty?
          brackets << '}'
        elsif type == brackets.last
          brackets.pop
        end

        if brackets.empty?
          if type == ';'
            node.source[:end] = get_position(token[2])
            node.source[:end][:offset] += 1
            @semicolon = true
            break
          elsif type == '{'
            open = true
            break
          elsif type == '}'
            if !params.empty?
              shift = params.length - 1
              prev = params[shift]
              while prev && prev[0] == 'space'
                shift -= 1
                prev = params[shift]
              end
              if prev
                node.source[:end] = get_position(prev[3] || prev[2])
                node.source[:end][:offset] += 1
              end
            end
            end_file
            break
          else
            params << token
          end
        else
          params << token
        end

        if @tokenizer[:end_of_file].call
          last = true
          break
        end
      end

      node.raws[:between] = spaces_and_comments_from_end(params)
      if !params.empty?
        node.raws[:after_name] = spaces_and_comments_from_start(params)
        raw(node, 'params', params)
        if last
          token = params.last
          node.source[:end] = get_position(token[3] || token[2])
          node.source[:end][:offset] += 1
          @spaces = node.raws[:between]
          node.raws[:between] = ''
        end
      else
        node.raws[:after_name] = ''
        node.params = ''
      end

      if open
        node.nodes = []
        @current = node
      end
    end

    def comment(token)
      node = Comment.new
      node.text = token[1]
      init(node, token[2])
      @current.append(node)
    end

    def empty_rule(token)
      node = Rule.new
      @current.append(node)
      node.selector = ''
      @semicolon = true
      end_file
    end

    def end_file
      if @current.parent
        @current = @current.parent
      end
    end

    def get_position(pos)
      return { column: 1, line: 1, offset: 0 } unless pos

      line = 1
      column = 1
      @input.css[0...pos].each_char do |char|
        if char == "\n"
          line += 1
          column = 1
        else
          column += 1
        end
      end
      { column: column, line: line, offset: pos }
    end

    def init(node, pos)
      node.source = { input: @input, start: get_position(pos) }
      @spaces = ''
    end

    def raw(node, prop, tokens)
      value = tokens.map { |t| t[1] }.join('')
      node.raws[prop] = value
      node.send("#{prop}=", value.strip)
    end

    def spaces_and_comments_from_end(tokens)
      result = ''
      tokens.reverse_each do |token|
        if token[0] == 'space' || token[0] == 'comment'
          result = token[1] + result
        else
          break
        end
      end
      result
    end

    def spaces_and_comments_from_start(tokens)
      result = ''
      tokens.each do |token|
        if token[0] == 'space' || token[0] == 'comment'
          result += token[1]
        else
          break
        end
      end
      result
    end

    def word(token)
      word = token[1]
      node = nil

      if word[0] == '.'
        node = Rule.new
        node.selector = word
      elsif word[0] == '#'
        node = Rule.new
        node.selector = word
      else
        node = Declaration.new
        node.prop = word
      end

      init(node, token[2])
      @current.append(node)

      if node.is_a?(Declaration)
        declaration(node)
      else
        rule(node)
      end
    end

    def declaration(node)
      tokens = []
      loop do
        token = @tokenizer[:next_token].call
        break unless token

        if token[0] == ':'
          node.raws[:between] = spaces_and_comments_from_end(tokens)
          tokens = []
          loop do
            token = @tokenizer[:next_token].call
            break unless token

            if token[0] == ';' || token[0] == '}'
              node.value = tokens.map { |t| t[1] }.join('').strip
              node.source[:end] = get_position(token[2])
              @semicolon = true if token[0] == ';'
              return
            else
              tokens << token
            end
          end
        else
          tokens << token
        end
      end
    end

    def rule(node)
      tokens = []
      loop do
        token = @tokenizer[:next_token].call
        break unless token

        if token[0] == '{'
          node.selector = (tokens.map { |t| t[1] }.join('') + node.selector).strip
          node.nodes = []
          @current = node
          return
        elsif token[0] == '}'
          end_file
          return
        else
          tokens << token
        end
      end
    end
  end
end
