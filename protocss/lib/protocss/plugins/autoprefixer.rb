# frozen_string_literal: true

module Protocss
  module Plugins
    class Autoprefixer
      # Browser support data (simplified)
      BROWSER_PREFIXES = {
        'transform' => ['-webkit-transform', '-ms-transform', 'transform'],
        'transition' => ['-webkit-transition', 'transition'],
        'animation' => ['-webkit-animation', 'animation'],
        'flex' => ['-webkit-box', '-webkit-flex', '-ms-flexbox', 'flex'],
        'flex-direction' => ['-webkit-box-orient', '-webkit-box-direction', '-webkit-flex-direction', '-ms-flex-direction', 'flex-direction'],
        'justify-content' => ['-webkit-box-pack', '-webkit-justify-content', '-ms-flex-pack', 'justify-content'],
        'align-items' => ['-webkit-box-align', '-webkit-align-items', '-ms-flex-align', 'align-items'],
        'user-select' => ['-webkit-user-select', '-moz-user-select', '-ms-user-select', 'user-select'],
        'appearance' => ['-webkit-appearance', '-moz-appearance', 'appearance'],
        'backface-visibility' => ['-webkit-backface-visibility', 'backface-visibility'],
        'perspective' => ['-webkit-perspective', 'perspective'],
        'transform-origin' => ['-webkit-transform-origin', '-ms-transform-origin', 'transform-origin'],
        'transition-property' => ['-webkit-transition-property', 'transition-property'],
        'transition-duration' => ['-webkit-transition-duration', 'transition-duration'],
        'transition-timing-function' => ['-webkit-transition-timing-function', 'transition-timing-function'],
        'transition-delay' => ['-webkit-transition-delay', 'transition-delay']
      }.freeze

      def initialize(opts = {})
        @browsers = opts[:browsers] || opts['browsers'] || ['> 1%', 'last 2 versions']
        @cascade = opts[:cascade] != false
        @add = opts[:add] != false
        @remove = opts[:remove] != false
      end

      def postcss_plugin
        'autoprefixer'
      end

      def Declaration(decl, helpers)
        prop = decl.prop
        return unless BROWSER_PREFIXES.key?(prop)

        prefixes = BROWSER_PREFIXES[prop]
        value = decl.value

        # Add prefixed versions before the standard property
        prefixes[0...-1].reverse.each do |prefixed_prop|
          decl.clone_before(Protocss.decl(prop: prefixed_prop, value: value))
        end
      end

      def to_plugin
        {
          postcss_plugin: 'autoprefixer',
          'Declaration' => ->(decl, helpers = {}) { Declaration(decl, helpers) }
        }
      end
    end
  end
end
