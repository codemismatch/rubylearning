# frozen_string_literal: true

module Protocss
  module Tokenize
    RE_AT_END = /[ \t\n\f\r"'()\/;\[\]\\{}]/
    RE_WORD_END = /[ \t\n\f\r!"'():;@\[\]\\{}]|\/(?=\*)/
    RE_BAD_BRACKET = /.[\r\n"'(\/\\]/
    RE_HEX_ESCAPE = /[\da-f]/i

    def self.tokenizer(input, options = {})
      css = input.css.to_s
      ignore = options[:ignore_errors] || false

      length = css.length
      pos = 0
      buffer = []
      returned = []

      position = -> { pos }

      unclosed = ->(what) { raise input.error("Unclosed #{what}", pos) }

      end_of_file = -> { returned.empty? && pos >= length }

      next_token = lambda do |opts = nil|
        opts ||= {}
        return returned.pop unless returned.empty?
        return nil if pos >= length

        ignore_unclosed = opts[:ignore_unclosed] || false
        code = css[pos].ord

        current_token = nil

        case code
        when "\n".ord, ' '.ord, "\t".ord, "\r".ord, "\f".ord
          next_pos = pos
          loop do
            next_pos += 1
            break if next_pos >= length
            char_code = css[next_pos].ord
            break unless [32, 10, 9, 13, 12].include?(char_code)
          end
          current_token = ['space', css[pos...next_pos], pos]
          pos = next_pos - 1

        when '['.ord, ']'.ord, '{'.ord, '}'.ord, ':'.ord, ';'.ord, ')'.ord
          control_char = css[pos]
          current_token = [control_char, control_char, pos]

        when '('.ord
          prev = buffer.empty? ? '' : buffer.pop[1]
          n = pos + 1 < length ? css[pos + 1].ord : 0
          if prev == 'url' && ![39, 34, 32, 10, 9, 12, 13].include?(n)
            next_pos = pos
            loop do
              escaped = false
              next_pos = css.index(')', next_pos + 1)
              if next_pos.nil?
                if ignore || ignore_unclosed
                  next_pos = pos
                  break
                else
                  unclosed.call('bracket')
                end
              end
              escape_pos = next_pos
              while escape_pos > 0 && css[escape_pos - 1].ord == 92
                escape_pos -= 1
                escaped = !escaped
              end
              break unless escaped
            end
            current_token = ['brackets', css[pos..next_pos], pos, next_pos]
            pos = next_pos
          else
            next_pos = css.index(')', pos + 1)
            content = next_pos ? css[pos..next_pos] : ''
            if next_pos.nil? || RE_BAD_BRACKET.match?(content)
              current_token = ['(', '(', pos]
            else
              current_token = ['brackets', content, pos, next_pos]
              pos = next_pos
            end
          end

        when "'".ord, '"'.ord
          quote = code == "'".ord ? "'" : '"'
          next_pos = pos
          loop do
            escaped = false
            next_pos = css.index(quote, next_pos + 1)
            if next_pos.nil?
              if ignore || ignore_unclosed
                next_pos = pos + 1
                break
              else
                unclosed.call('string')
              end
            end
            escape_pos = next_pos
            while escape_pos > 0 && css[escape_pos - 1].ord == 92
              escape_pos -= 1
              escaped = !escaped
            end
            break unless escaped
          end
          current_token = ['string', css[pos..next_pos], pos, next_pos]
          pos = next_pos

        when '@'.ord
          match = css[(pos + 1)..-1]&.match(RE_AT_END)
          if match
            next_pos = pos + 1 + match.begin(0)
          else
            next_pos = length - 1
          end
          current_token = ['at-word', css[pos..next_pos], pos, next_pos]
          pos = next_pos

        when '\\'.ord
          next_pos = pos
          escape = true
          while next_pos + 1 < length && css[next_pos + 1].ord == 92
            next_pos += 1
            escape = !escape
          end
          char_code = next_pos + 1 < length ? css[next_pos + 1].ord : 0
          if escape && ![47, 32, 10, 9, 13, 12].include?(char_code)
            next_pos += 1
            if next_pos < length && RE_HEX_ESCAPE.match?(css[next_pos])
              while next_pos + 1 < length && RE_HEX_ESCAPE.match?(css[next_pos + 1])
                next_pos += 1
              end
              next_pos += 1 if next_pos + 1 < length && css[next_pos + 1].ord == 32
            end
          end
          current_token = ['word', css[pos..next_pos], pos, next_pos]
          buffer << current_token
          pos = next_pos

        else
          if code == '/'.ord && pos + 1 < length && css[pos + 1].ord == '*'.ord
            next_pos = css.index('*/', pos + 2)
            if next_pos.nil?
              if ignore || ignore_unclosed
                next_pos = length
              else
                unclosed.call('comment')
              end
            else
              next_pos += 1
            end
            current_token = ['comment', css[pos..next_pos], pos, next_pos]
            pos = next_pos
          else
            match = css[(pos + 1)..-1]&.match(RE_WORD_END)
            if match
              next_pos = pos + 1 + match.begin(0)
            else
              next_pos = length - 1
            end
            current_token = ['word', css[pos..next_pos], pos, next_pos]
            buffer << current_token
            pos = next_pos
          end
        end

        pos += 1
        current_token
      end

      back = ->(token) { returned << token }

      {
        back: back,
        end_of_file: end_of_file,
        next_token: next_token,
        position: position
      }
    end
  end
end
