# frozen_string_literal: true

require_relative 'tailwind/config_loader'
require_relative 'tailwind/utility_generator'
require_relative 'tailwind/content_scanner'
require_relative 'tailwind/variant_generator'

module Protocss
  module Plugins
    class Tailwind
      attr_accessor :config, :content_paths, :theme, :plugins

      def initialize(config = {})
        @config = load_config(config)
        @content_paths = @config[:content] || @config['content'] || []
        @theme = @config[:theme] || @config['theme'] || {}
        @plugins = @config[:plugins] || @config['plugins'] || []
        @mode = @config[:mode] || @config['mode'] || 'aot' # 'jit' or 'aot'
        @safelist = @config[:safelist] || @config['safelist'] || []
        @dark_mode = @config[:darkMode] || @config['darkMode'] || 'media'
        @content_scanner = nil
        @variant_generator = VariantGenerator.new(@config)
        @utility_cache = {}
      end

      def postcss_plugin
        'tailwind'
      end

      def Once(root, helpers)
        @root = root
        @helpers = helpers
        process_tailwind_directives
      end

      private

      def load_config(config)
        if config.is_a?(String)
          # Load from file
          if File.exist?(config)
            ConfigLoader.load(config)
          else
            {}
          end
        elsif config.is_a?(Hash)
          config
        else
          # Try to load from default locations
          ConfigLoader.load_default
        end
      end

      def process_tailwind_directives
        new_nodes = []
        nodes_to_remove = []

        # Initialize content scanner if in JIT mode
        if @mode == 'jit' && !@content_paths.empty?
          @content_scanner = ContentScanner.new(@content_paths)
          @used_classes = @content_scanner.scan + @safelist
        end

        @root.nodes.each do |node|
          if node.type == 'atrule' && node.name == 'tailwind'
            directive = node.params.strip
            nodes_to_remove << node

            case directive
            when 'base'
              new_nodes.concat(generate_base_styles)
            when 'components'
              new_nodes.concat(generate_component_styles)
            when 'utilities'
              new_nodes.concat(generate_utility_styles)
            when 'variants'
              new_nodes.concat(generate_variant_styles)
            end
          elsif node.type == 'atrule' && node.name == 'apply'
            process_apply_directive(node)
          end
        end

        # Remove processed @tailwind directives
        nodes_to_remove.each(&:remove)

        # Insert generated styles
        new_nodes.reverse.each do |node|
          @root.prepend(node)
        end
      end

      def generate_base_styles
        [
          create_base_rule('*, ::before, ::after', [
            ['box-sizing', 'border-box'],
            ['border-width', '0'],
            ['border-style', 'solid'],
            ['border-color', 'currentColor']
          ]),
          create_base_rule('::before, ::after', [
            ['--tw-content', '""'],
            ['content', 'var(--tw-content)']
          ]),
          create_base_rule('html', [
            ['line-height', '1.5'],
            ['-webkit-text-size-adjust', '100%'],
            ['-moz-tab-size', '4'],
            ['tab-size', '4'],
            ['font-family', get_font_family]
          ]),
          create_base_rule('body', [
            ['margin', '0'],
            ['line-height', 'inherit']
          ])
        ]
      end

      def create_base_rule(selector, declarations)
        rule = Protocss.rule(selector: selector)
        declarations.each do |prop, value|
          rule.append(Protocss.decl(prop: prop, value: value))
        end
        rule
      end

      def generate_component_styles
        # Component styles from config
        components = @theme[:components] || @theme['components'] || {}
        styles = []

        components.each do |name, rules|
          rule = Protocss.rule(selector: ".#{name}")
          if rules.is_a?(Hash)
            rules.each do |prop, value|
              rule.append(Protocss.decl(prop: prop.to_s, value: value.to_s))
            end
          end
          styles << rule
        end

        styles
      end

      def generate_utility_styles
        generator = UtilityGenerator.new(@config)
        
        if @mode == 'jit' && @used_classes
          # JIT mode: only generate utilities for used classes
          generate_jit_utilities(generator)
        else
          # AOT mode: generate all utilities with variants
          generate_aot_utilities(generator)
        end
      end

      def generate_jit_utilities(generator)
        utilities = []
        
        @used_classes.each do |class_name|
          # Parse class name for variants (e.g., "md:hover:bg-blue-500")
          parts = class_name.split(':')
          base_class = parts.pop
          variants = parts

          # Generate base utility
          utility = generator.generate_for_class(base_class)
          next unless utility

          # Apply variants if any
          if variants.empty?
            utilities << utility
          else
            variant_rules = @variant_generator.apply_variants(utility, variants, class_name)
            utilities.concat(variant_rules)
          end
        end

        utilities
      end

      def generate_aot_utilities(generator)
        # Generate all base utilities
        base_utilities = generator.generate
        
        # Apply common variants to all utilities
        utilities_with_variants = []
        
        base_utilities.each do |utility|
          # Add base utility
          utilities_with_variants << utility
          
          # Extract class name from selector
          if utility.selector && utility.selector.start_with?('.')
            class_name = utility.selector[1..-1]
            
            # Generate common variants
            %w[hover focus active disabled sm md lg xl 2xl dark].each do |variant|
              variant_rule = @variant_generator.apply_single_variant(utility, variant, class_name)
              utilities_with_variants << variant_rule if variant_rule
            end
          end
        end
        
        utilities_with_variants
      end

      def generate_variant_styles
        # Variant styles (responsive, hover, etc.)
        []
      end

      def process_apply_directive(node)
        # Process @apply directive
        classes = node.params.strip.split(/\s+/)
        parent = node.parent

        classes.each do |class_name|
          utility_rule = generate_utility_for_class(class_name)
          if utility_rule && utility_rule.nodes
            utility_rule.nodes.each do |decl|
              parent.append(decl.clone)
            end
          end
        end

        node.remove
      end

      def generate_utility_for_class(class_name)
        generator = UtilityGenerator.new(@config)
        generator.generate_for_class(class_name)
      end

      def get_font_family
        font_family = @theme[:fontFamily] || @theme['fontFamily'] || {}
        default_fonts = font_family[:sans] || font_family['sans'] || [
          'ui-sans-serif',
          'system-ui',
          '-apple-system',
          'BlinkMacSystemFont',
          '"Segoe UI"',
          'Roboto',
          '"Helvetica Neue"',
          'Arial',
          '"Noto Sans"',
          'sans-serif'
        ]
        default_fonts.join(', ')
      end
    end
  end
end
