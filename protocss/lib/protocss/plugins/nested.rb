# frozen_string_literal: true

module Protocss
  module Plugins
    class Nested
      def initialize(opts = {})
        @bubble = opts[:bubble] || ['media', 'supports']
        @preserve_empty = opts[:preserve_empty] || false
      end

      def postcss_plugin
        'nested'
      end

      def handle_rule(rule, _helpers = {})
        return unless rule.nodes

        new_nodes = []
        nodes_to_remove = []

        rule.nodes.each do |node|
          if node.type == 'rule'
            # Unwrap nested rule
            nested_rule = node
            selector = nested_rule.selector

            # Combine selectors
            if selector.start_with?('&')
              # Parent selector reference
              new_selector = rule.selector + selector[1..-1]
            elsif selector.include?('&')
              # Parent selector in middle
              new_selector = selector.gsub('&', rule.selector)
            else
              # Descendant selector
              new_selector = "#{rule.selector} #{selector}"
            end

            # Create new rule with combined selector
            new_rule = Protocss.rule(selector: new_selector)

            # Move declarations from nested rule
            nested_rule.nodes.each do |child|
              new_rule.append(child.clone)
            end

            new_nodes << new_rule
            nodes_to_remove << node
          end
        end

        # Remove nested rules
        nodes_to_remove.each(&:remove)

        # Insert unwrapped rules after current rule
        new_nodes.each do |new_rule|
          rule.parent.insert_after(rule, new_rule)
        end
      end

      def to_plugin
        {
          postcss_plugin: 'nested',
          'Rule' => ->(rule, helpers = {}) { handle_rule(rule, helpers) }
        }
      end
    end
  end
end
