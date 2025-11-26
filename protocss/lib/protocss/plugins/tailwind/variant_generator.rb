# frozen_string_literal: true

module Protocss
  module Plugins
    module Tailwind
      class VariantGenerator
        attr_reader :config, :theme

        # Default breakpoints for responsive variants
        DEFAULT_SCREENS = {
          'sm' => '640px',
          'md' => '768px',
          'lg' => '1024px',
          'xl' => '1280px',
          '2xl' => '1536px'
        }.freeze

        def initialize(config = {})
          @config = config
          @theme = config[:theme] || config['theme'] || {}
          @dark_mode = config[:darkMode] || config['darkMode'] || 'media'
        end

        # Wrap a utility rule with variants
        def apply_variants(base_rule, variants, class_name)
          return [base_rule] if variants.empty?

          rules = []
          variant_stack = []

          # Process variants in order (responsive should be outermost)
          sorted_variants = sort_variants(variants)

          sorted_variants.each do |variant|
            variant_stack << variant
          end

          # Generate the rule with all variants applied
          wrapped_rule = wrap_with_variants(base_rule, variant_stack, class_name)
          rules << wrapped_rule if wrapped_rule

          rules
        end

        # Generate all variant combinations for a utility
        def generate_variants_for_utility(base_rule, utility_name, enabled_variants = nil)
          rules = [base_rule]
          enabled_variants ||= default_enabled_variants

          enabled_variants.each do |variant_name|
            variant_rule = apply_single_variant(base_rule, variant_name, utility_name)
            rules << variant_rule if variant_rule
          end

          rules
        end

        # Apply a single variant to a rule
        def apply_single_variant(base_rule, variant_name, utility_name)
          selector = base_rule.selector
          new_selector = generate_variant_selector(selector, variant_name)
          return nil unless new_selector

          # Create new rule with variant selector
          rule = Protocss.rule(selector: new_selector)
          
          # Copy declarations from base rule
          base_rule.nodes&.each do |node|
            if node.type == 'decl'
              rule.append(Protocss.decl(prop: node.prop, value: node.value))
            end
          end

          # Wrap in media query if needed
          wrap_in_media_query(rule, variant_name)
        end

        private

        def sort_variants(variants)
          # Order: responsive > dark > state > pseudo-class > pseudo-element
          order = {
            'responsive' => 0,
            'dark' => 1,
            'group' => 2,
            'peer' => 3,
            'state' => 4,
            'pseudo-class' => 5,
            'pseudo-element' => 6
          }

          variants.sort_by { |v| order[variant_type(v)] || 999 }
        end

        def variant_type(variant)
          case variant
          when /^(sm|md|lg|xl|2xl)$/ then 'responsive'
          when 'dark' then 'dark'
          when /^group-/ then 'group'
          when /^peer-/ then 'peer'
          when /^(hover|focus|active|visited|disabled|enabled|checked)$/ then 'state'
          when /^(first|last|odd|even|first-of-type|last-of-type)$/ then 'pseudo-class'
          when /^(before|after|placeholder|selection|marker)$/ then 'pseudo-element'
          else 'unknown'
          end
        end

        def wrap_with_variants(rule, variants, class_name)
          return rule if variants.empty?

          current_rule = rule
          variants.reverse.each do |variant|
            current_rule = apply_variant_wrapper(current_rule, variant, class_name)
          end
          current_rule
        end

        def apply_variant_wrapper(rule, variant, class_name)
          case variant
          when /^(sm|md|lg|xl|2xl)$/
            wrap_responsive(rule, variant)
          when 'dark'
            wrap_dark_mode(rule)
          when /^group-(.+)$/
            wrap_group(rule, $1)
          when /^peer-(.+)$/
            wrap_peer(rule, $1)
          else
            wrap_state_or_pseudo(rule, variant)
          end
        end

        def generate_variant_selector(base_selector, variant)
          # Remove the leading dot from class selector
          class_name = base_selector.sub(/^\./, '')

          case variant
          when /^(sm|md|lg|xl|2xl)$/
            # Responsive variants don't change selector, just wrap in media query
            base_selector
          when 'dark'
            if @dark_mode == 'class'
              ".dark #{base_selector}"
            else
              base_selector
            end
          when 'hover'
            "#{base_selector}:hover"
          when 'focus'
            "#{base_selector}:focus"
          when 'focus-visible'
            "#{base_selector}:focus-visible"
          when 'focus-within'
            "#{base_selector}:focus-within"
          when 'active'
            "#{base_selector}:active"
          when 'visited'
            "#{base_selector}:visited"
          when 'target'
            "#{base_selector}:target"
          when 'disabled'
            "#{base_selector}:disabled"
          when 'enabled'
            "#{base_selector}:enabled"
          when 'checked'
            "#{base_selector}:checked"
          when 'indeterminate'
            "#{base_selector}:indeterminate"
          when 'default'
            "#{base_selector}:default"
          when 'required'
            "#{base_selector}:required"
          when 'valid'
            "#{base_selector}:valid"
          when 'invalid'
            "#{base_selector}:invalid"
          when 'in-range'
            "#{base_selector}:in-range"
          when 'out-of-range'
            "#{base_selector}:out-of-range"
          when 'placeholder-shown'
            "#{base_selector}:placeholder-shown"
          when 'autofill'
            "#{base_selector}:autofill"
          when 'read-only'
            "#{base_selector}:read-only"
          when 'first'
            "#{base_selector}:first-child"
          when 'last'
            "#{base_selector}:last-child"
          when 'only'
            "#{base_selector}:only-child"
          when 'odd'
            "#{base_selector}:nth-child(odd)"
          when 'even'
            "#{base_selector}:nth-child(even)"
          when 'first-of-type'
            "#{base_selector}:first-of-type"
          when 'last-of-type'
            "#{base_selector}:last-of-type"
          when 'only-of-type'
            "#{base_selector}:only-of-type"
          when 'empty'
            "#{base_selector}:empty"
          when 'before'
            "#{base_selector}::before"
          when 'after'
            "#{base_selector}::after"
          when 'placeholder'
            "#{base_selector}::placeholder"
          when 'selection'
            "#{base_selector}::selection"
          when 'marker'
            "#{base_selector}::marker"
          when 'file'
            "#{base_selector}::file-selector-button"
          when /^group-(.+)$/
            state = $1
            ".group:#{state} #{base_selector}"
          when /^peer-(.+)$/
            state = $1
            ".peer:#{state} ~ #{base_selector}"
          else
            base_selector
          end
        end

        def wrap_in_media_query(rule, variant)
          case variant
          when /^(sm|md|lg|xl|2xl)$/
            screens = get_screens
            breakpoint = screens[variant] || screens[variant.to_sym]
            return rule unless breakpoint

            at_rule = Protocss.at_rule(
              name: 'media',
              params: "(min-width: #{breakpoint})"
            )
            at_rule.nodes = [rule]
            at_rule
          when 'dark'
            if @dark_mode == 'media'
              at_rule = Protocss.at_rule(
                name: 'media',
                params: '(prefers-color-scheme: dark)'
              )
              at_rule.nodes = [rule]
              at_rule
            else
              rule
            end
          else
            rule
          end
        end

        def wrap_responsive(rule, breakpoint)
          screens = get_screens
          min_width = screens[breakpoint] || screens[breakpoint.to_sym]
          return rule unless min_width

          at_rule = Protocss.at_rule(
            name: 'media',
            params: "(min-width: #{min_width})"
          )
          at_rule.nodes = [rule]
          at_rule
        end

        def wrap_dark_mode(rule)
          if @dark_mode == 'media'
            at_rule = Protocss.at_rule(
              name: 'media',
              params: '(prefers-color-scheme: dark)'
            )
            at_rule.nodes = [rule]
            at_rule
          else
            # Class strategy - selector already modified
            rule
          end
        end

        def wrap_group(rule, state)
          # Selector already modified in generate_variant_selector
          rule
        end

        def wrap_peer(rule, state)
          # Selector already modified in generate_variant_selector
          rule
        end

        def wrap_state_or_pseudo(rule, variant)
          # Selector already modified in generate_variant_selector
          rule
        end

        def get_screens
          @theme[:screens] || @theme['screens'] || DEFAULT_SCREENS
        end

        def default_enabled_variants
          %w[
            hover focus active disabled
            first last odd even
            sm md lg xl 2xl
          ]
        end
      end
    end
  end
end
