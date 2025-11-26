# frozen_string_literal: true

module Protocss
  module List
    def self.comma(string)
      split(string, [','], true)
    end

    def self.space(string)
      spaces = [' ', "\n", "\t"]
      split(string, spaces)
    end

    def self.split(string, separators, last = false)
      array = []
      current = ''
      split_flag = false

      func = 0
      in_quote = false
      prev_quote = ''
      escape = false

      string.each_char do |letter|
        if escape
          escape = false
        elsif letter == '\\'
          escape = true
        elsif in_quote
          if letter == prev_quote
            in_quote = false
          end
        elsif letter == '"' || letter == "'"
          in_quote = true
          prev_quote = letter
        elsif letter == '('
          func += 1
        elsif letter == ')'
          func -= 1 if func > 0
        elsif func == 0
          split_flag = true if separators.include?(letter)
        end

        if split_flag
          array << current.strip unless current.empty?
          current = ''
          split_flag = false
        else
          current += letter
        end
      end

      array << current.strip if last || !current.empty?
      array
    end
  end
end
