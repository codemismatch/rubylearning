# frozen_string_literal: true

module Protocss
  module Plugins
    module Tailwind
      class UtilityGenerator
        def initialize(config)
          @config = config
          @theme = config[:theme] || config['theme'] || {}
          @utilities = []
        end

        def generate
          generate_spacing_utilities
          generate_color_utilities
          generate_typography_utilities
          generate_layout_utilities
          generate_flexbox_utilities
          generate_grid_utilities
          generate_border_utilities
          generate_background_utilities
          generate_text_utilities
          generate_display_utilities
          generate_position_utilities
          generate_size_utilities
          generate_transform_utilities
          generate_transition_utilities
          generate_animation_utilities
          generate_filter_utilities
          generate_shadow_utilities
          generate_opacity_utilities
          generate_z_index_utilities
          generate_overflow_utilities
          generate_interactivity_utilities
          generate_accessibility_utilities
          @utilities
        end

        def generate_for_class(class_name)
          # Parse class name and generate utility
          case class_name
          when /^p(t|r|b|l|x|y)?-(\d+|px|full|auto)$/
            generate_spacing_utility(class_name)
          when /^m(t|r|b|l|x|y)?-(\d+|px|full|auto)$/
            generate_spacing_utility(class_name)
          when /^p-(\d+|px|full|auto)$/
            generate_padding_utility(class_name)
          when /^m-(\d+|px|full|auto)$/
            generate_margin_utility(class_name)
          when /^w-(full|auto|\d+|px|screen|1\/2|1\/3|2\/3|1\/4|3\/4)$/
            generate_width_utility(class_name)
          when /^h-(full|auto|\d+|px|screen)$/
            generate_height_utility(class_name)
          when /^bg-(\w+)(?:-(\d+))?$/
            generate_color_utility(class_name, 'background-color')
          when /^text-(\w+)(?:-(\d+))?$/
            generate_color_utility(class_name, 'color')
          when /^rounded(?:-(\w+))?$/
            generate_rounded_utility(class_name)
          when /^flex$/
            rule = Protocss.rule(selector: ".#{class_name}")
            rule.append(Protocss.decl(prop: 'display', value: 'flex'))
            rule
          when /^grid$/
            rule = Protocss.rule(selector: ".#{class_name}")
            rule.append(Protocss.decl(prop: 'display', value: 'grid'))
            rule
          when /^hidden$/
            rule = Protocss.rule(selector: ".#{class_name}")
            rule.append(Protocss.decl(prop: 'display', value: 'none'))
            rule
          else
            nil
          end
        end

        private

        def generate_spacing_utilities
          spacing = get_theme_value(:spacing) || {
            '0' => '0px',
            '1' => '0.25rem',
            '2' => '0.5rem',
            '3' => '0.75rem',
            '4' => '1rem',
            '5' => '1.25rem',
            '6' => '1.5rem',
            '8' => '2rem',
            '10' => '2.5rem',
            '12' => '3rem',
            '16' => '4rem',
            '20' => '5rem',
            '24' => '6rem',
            'px' => '1px'
          }

          %w[p m].each do |prefix|
            %w[t r b l x y].each do |direction|
              spacing.each do |key, value|
                class_name = "#{prefix}#{direction}-#{key}"
                selector = ".#{class_name}"
                rule = Protocss.rule(selector: selector)

                prop = case prefix
                       when 'p' then 'padding'
                       when 'm' then 'margin'
                       end

                case direction
                when 't'
                  rule.append(Protocss.decl(prop: "#{prop}-top", value: value))
                when 'r'
                  rule.append(Protocss.decl(prop: "#{prop}-right", value: value))
                when 'b'
                  rule.append(Protocss.decl(prop: "#{prop}-bottom", value: value))
                when 'l'
                  rule.append(Protocss.decl(prop: "#{prop}-left", value: value))
                when 'x'
                  rule.append(Protocss.decl(prop: "#{prop}-left", value: value))
                  rule.append(Protocss.decl(prop: "#{prop}-right", value: value))
                when 'y'
                  rule.append(Protocss.decl(prop: "#{prop}-top", value: value))
                  rule.append(Protocss.decl(prop: "#{prop}-bottom", value: value))
                end

                @utilities << rule
              end
            end
          end

          # Full padding/margin
          spacing.each do |key, value|
            %w[p m].each do |prefix|
              class_name = "#{prefix}-#{key}"
              rule = Protocss.rule(selector: ".#{class_name}")
              prop = prefix == 'p' ? 'padding' : 'margin'
              rule.append(Protocss.decl(prop: prop, value: value))
              @utilities << rule
            end
          end
        end

        def generate_color_utilities
          colors = get_theme_value(:colors) || {
            'black' => '#000000',
            'white' => '#ffffff',
            'gray' => {
              '100' => '#f7fafc',
              '200' => '#edf2f7',
              '300' => '#e2e8f0',
              '400' => '#cbd5e0',
              '500' => '#a0aec0',
              '600' => '#718096',
              '700' => '#4a5568',
              '800' => '#2d3748',
              '900' => '#1a202c'
            },
            'red' => {
              '500' => '#ef4444',
              '600' => '#dc2626'
            },
            'blue' => {
              '500' => '#3b82f6',
              '600' => '#2563eb'
            }
          }

          generate_color_classes(colors, 'bg-', 'background-color')
          generate_color_classes(colors, 'text-', 'color')
          generate_color_classes(colors, 'border-', 'border-color')
        end

        def generate_color_classes(colors, prefix, property)
          colors.each do |name, value|
            if value.is_a?(Hash)
              value.each do |shade, color_value|
                class_name = "#{prefix}#{name}-#{shade}"
                rule = Protocss.rule(selector: ".#{class_name}")
                rule.append(Protocss.decl(prop: property, value: color_value))
                @utilities << rule
              end
            else
              class_name = "#{prefix}#{name}"
              rule = Protocss.rule(selector: ".#{class_name}")
              rule.append(Protocss.decl(prop: property, value: value))
              @utilities << rule
            end
          end
        end

        def generate_typography_utilities
          # Font sizes
          font_sizes = get_theme_value(:fontSize) || {
            'xs' => ['0.75rem', { lineHeight: '1rem' }],
            'sm' => ['0.875rem', { lineHeight: '1.25rem' }],
            'base' => ['1rem', { lineHeight: '1.5rem' }],
            'lg' => ['1.125rem', { lineHeight: '1.75rem' }],
            'xl' => ['1.25rem', { lineHeight: '1.75rem' }],
            '2xl' => ['1.5rem', { lineHeight: '2rem' }],
            '3xl' => ['1.875rem', { lineHeight: '2.25rem' }],
            '4xl' => ['2.25rem', { lineHeight: '2.5rem' }]
          }

          font_sizes.each do |size, config|
            class_name = "text-#{size}"
            rule = Protocss.rule(selector: ".#{class_name}")
            if config.is_a?(Array)
              rule.append(Protocss.decl(prop: 'font-size', value: config[0]))
              if config[1] && config[1][:lineHeight]
                rule.append(Protocss.decl(prop: 'line-height', value: config[1][:lineHeight]))
              end
            else
              rule.append(Protocss.decl(prop: 'font-size', value: config.to_s))
            end
            @utilities << rule
          end

          # Font weights
          font_weights = get_theme_value(:fontWeight) || {
            'thin' => '100',
            'light' => '300',
            'normal' => '400',
            'medium' => '500',
            'semibold' => '600',
            'bold' => '700',
            'extrabold' => '800',
            'black' => '900'
          }

          font_weights.each do |weight, value|
            class_name = "font-#{weight}"
            rule = Protocss.rule(selector: ".#{class_name}")
            rule.append(Protocss.decl(prop: 'font-weight', value: value))
            @utilities << rule
          end
        end

        def generate_layout_utilities
          # Display
          %w[block inline inline-block flex grid table].each do |display|
            rule = Protocss.rule(selector: ".#{display}")
            rule.append(Protocss.decl(prop: 'display', value: display))
            @utilities << rule
          end

          # Hidden
          rule = Protocss.rule(selector: '.hidden')
          rule.append(Protocss.decl(prop: 'display', value: 'none'))
          @utilities << rule
        end

        def generate_flexbox_utilities
          # Flex direction
          %w[row row-reverse col col-reverse].each do |direction|
            rule = Protocss.rule(selector: ".flex-#{direction}")
            value = direction == 'col' ? 'column' : direction == 'col-reverse' ? 'column-reverse' : direction
            rule.append(Protocss.decl(prop: 'flex-direction', value: value))
            @utilities << rule
          end

          # Justify content
          %w[start end center between around evenly].each do |justify|
            rule = Protocss.rule(selector: ".justify-#{justify}")
            value = case justify
                    when 'start' then 'flex-start'
                    when 'end' then 'flex-end'
                    when 'between' then 'space-between'
                    when 'around' then 'space-around'
                    when 'evenly' then 'space-evenly'
                    else justify
                    end
            rule.append(Protocss.decl(prop: 'justify-content', value: value))
            @utilities << rule
          end

          # Align items
          %w[start end center stretch baseline].each do |align|
            rule = Protocss.rule(selector: ".items-#{align}")
            value = case align
                    when 'start' then 'flex-start'
                    when 'end' then 'flex-end'
                    else align
                    end
            rule.append(Protocss.decl(prop: 'align-items', value: value))
            @utilities << rule
          end
        end

        def generate_grid_utilities
          # Grid template columns
          (1..12).each do |cols|
            rule = Protocss.rule(selector: ".grid-cols-#{cols}")
            rule.append(Protocss.decl(prop: 'grid-template-columns', value: "repeat(#{cols}, minmax(0, 1fr))"))
            @utilities << rule
          end
        end

        def generate_border_utilities
          # Border radius
          radius = get_theme_value(:borderRadius) || {
            'none' => '0',
            'sm' => '0.125rem',
            'DEFAULT' => '0.25rem',
            'md' => '0.375rem',
            'lg' => '0.5rem',
            'xl' => '0.75rem',
            '2xl' => '1rem',
            'full' => '9999px'
          }

          radius.each do |name, value|
            class_name = name == 'DEFAULT' ? 'rounded' : "rounded-#{name}"
            rule = Protocss.rule(selector: ".#{class_name}")
            rule.append(Protocss.decl(prop: 'border-radius', value: value))
            @utilities << rule
          end
        end

        def generate_background_utilities
          # Background size
          rule = Protocss.rule(selector: '.bg-cover')
          rule.append(Protocss.decl(prop: 'background-size', value: 'cover'))
          @utilities << rule

          rule = Protocss.rule(selector: '.bg-contain')
          rule.append(Protocss.decl(prop: 'background-size', value: 'contain'))
          @utilities << rule
        end

        def generate_text_utilities
          # Text align
          %w[left center right justify].each do |align|
            rule = Protocss.rule(selector: ".text-#{align}")
            rule.append(Protocss.decl(prop: 'text-align', value: align))
            @utilities << rule
          end

          # Text transform
          %w[uppercase lowercase capitalize].each do |transform|
            rule = Protocss.rule(selector: ".#{transform}")
            rule.append(Protocss.decl(prop: 'text-transform', value: transform))
            @utilities << rule
          end
        end

        def generate_display_utilities
          # Already handled in layout_utilities
        end

        def generate_position_utilities
          %w[static fixed absolute relative sticky].each do |position|
            rule = Protocss.rule(selector: ".#{position}")
            rule.append(Protocss.decl(prop: 'position', value: position))
            @utilities << rule
          end
        end

        def generate_size_utilities
          # Width
          widths = get_theme_value(:width) || {
            'auto' => 'auto',
            'full' => '100%',
            'screen' => '100vw',
            '1/2' => '50%',
            '1/3' => '33.333333%',
            '2/3' => '66.666667%',
            '1/4' => '25%',
            '3/4' => '75%'
          }

          widths.each do |name, value|
            rule = Protocss.rule(selector: ".w-#{name}")
            rule.append(Protocss.decl(prop: 'width', value: value))
            @utilities << rule
          end

          # Height
          heights = get_theme_value(:height) || {
            'auto' => 'auto',
            'full' => '100%',
            'screen' => '100vh'
          }

          heights.each do |name, value|
            rule = Protocss.rule(selector: ".h-#{name}")
            rule.append(Protocss.decl(prop: 'height', value: value))
            @utilities << rule
          end
        end

        def generate_spacing_utility(class_name)
          # Parse class like px-4, py-2, pt-1, etc.
          match = class_name.match(/^(p|m)(t|r|b|l|x|y)?-(\d+|px|full|auto)$/)
          return nil unless match

          prefix = match[1]
          direction = match[2] || ''
          size = match[3]

          spacing = get_theme_value(:spacing) || default_spacing
          value = spacing[size] || spacing[size.to_sym] || "#{size.to_i * 0.25}rem"

          prop = prefix == 'p' ? 'padding' : 'margin'
          rule = Protocss.rule(selector: ".#{class_name}")

          case direction
          when 't'
            rule.append(Protocss.decl(prop: "#{prop}-top", value: value))
          when 'r'
            rule.append(Protocss.decl(prop: "#{prop}-right", value: value))
          when 'b'
            rule.append(Protocss.decl(prop: "#{prop}-bottom", value: value))
          when 'l'
            rule.append(Protocss.decl(prop: "#{prop}-left", value: value))
          when 'x'
            rule.append(Protocss.decl(prop: "#{prop}-left", value: value))
            rule.append(Protocss.decl(prop: "#{prop}-right", value: value))
          when 'y'
            rule.append(Protocss.decl(prop: "#{prop}-top", value: value))
            rule.append(Protocss.decl(prop: "#{prop}-bottom", value: value))
          else
            rule.append(Protocss.decl(prop: prop, value: value))
          end

          rule
        end

        def generate_padding_utility(class_name)
          match = class_name.match(/^p-(\d+|px|full|auto)$/)
          return nil unless match

          size = match[1]
          spacing = get_theme_value(:spacing) || default_spacing
          value = spacing[size] || spacing[size.to_sym] || "#{size.to_i * 0.25}rem"

          rule = Protocss.rule(selector: ".#{class_name}")
          rule.append(Protocss.decl(prop: 'padding', value: value))
          rule
        end

        def generate_margin_utility(class_name)
          match = class_name.match(/^m-(\d+|px|full|auto)$/)
          return nil unless match

          size = match[1]
          spacing = get_theme_value(:spacing) || default_spacing
          value = spacing[size] || spacing[size.to_sym] || "#{size.to_i * 0.25}rem"

          rule = Protocss.rule(selector: ".#{class_name}")
          rule.append(Protocss.decl(prop: 'margin', value: value))
          rule
        end

        def generate_width_utility(class_name)
          match = class_name.match(/^w-(full|auto|\d+|px|screen|1\/2|1\/3|2\/3|1\/4|3\/4)$/)
          return nil unless match

          size = match[1]
          widths = get_theme_value(:width) || default_widths
          value = widths[size] || widths[size.to_sym] || (size.match?(/^\d+$/) ? "#{size.to_i * 0.25}rem" : size)

          rule = Protocss.rule(selector: ".#{class_name}")
          rule.append(Protocss.decl(prop: 'width', value: value))
          rule
        end

        def generate_height_utility(class_name)
          match = class_name.match(/^h-(full|auto|\d+|px|screen)$/)
          return nil unless match

          size = match[1]
          heights = get_theme_value(:height) || default_heights
          value = heights[size] || heights[size.to_sym] || (size.match?(/^\d+$/) ? "#{size.to_i * 0.25}rem" : size)

          rule = Protocss.rule(selector: ".#{class_name}")
          rule.append(Protocss.decl(prop: 'height', value: value))
          rule
        end

        def generate_color_utility(class_name, property)
          match = class_name.match(/^(bg|text)-(\w+)(?:-(\d+))?$/)
          return nil unless match

          color_name = match[2]
          shade = match[3]

          colors = get_theme_value(:colors) || default_colors
          color_hash = colors[color_name] || colors[color_name.to_sym]

          if color_hash.is_a?(Hash)
            shade_key = shade || '500'
            color_value = color_hash[shade_key] || color_hash[shade_key.to_sym]
          else
            color_value = color_hash
          end

          return nil unless color_value

          rule = Protocss.rule(selector: ".#{class_name}")
          rule.append(Protocss.decl(prop: property, value: color_value.to_s))
          rule
        end

        def generate_rounded_utility(class_name)
          match = class_name.match(/^rounded(?:-(\w+))?$/)
          return nil unless match

          size = match[1] || 'DEFAULT'
          radius = get_theme_value(:borderRadius) || default_border_radius
          value = radius[size] || radius[size.to_sym] || radius['DEFAULT'] || '0.25rem'

          rule = Protocss.rule(selector: ".#{class_name}")
          rule.append(Protocss.decl(prop: 'border-radius', value: value))
          rule
        end

        def default_spacing
          {
            '0' => '0px',
            '1' => '0.25rem',
            '2' => '0.5rem',
            '3' => '0.75rem',
            '4' => '1rem',
            '5' => '1.25rem',
            '6' => '1.5rem',
            '8' => '2rem',
            '10' => '2.5rem',
            '12' => '3rem',
            '16' => '4rem',
            '20' => '5rem',
            '24' => '6rem',
            'px' => '1px'
          }
        end

        def default_widths
          {
            'auto' => 'auto',
            'full' => '100%',
            'screen' => '100vw',
            '1/2' => '50%',
            '1/3' => '33.333333%',
            '2/3' => '66.666667%',
            '1/4' => '25%',
            '3/4' => '75%'
          }
        end

        def default_heights
          {
            'auto' => 'auto',
            'full' => '100%',
            'screen' => '100vh'
          }
        end

        def default_colors
          {
            'primary' => '#3b82f6',
            'white' => '#ffffff',
            'black' => '#000000',
            'gray' => {
              '100' => '#f7fafc',
              '500' => '#a0aec0',
              '900' => '#1a202c'
            },
            'blue' => {
              '500' => '#3b82f6',
              '600' => '#2563eb'
            }
          }
        end

        def default_border_radius
          {
            'none' => '0',
            'sm' => '0.125rem',
            'DEFAULT' => '0.25rem',
            'md' => '0.375rem',
            'lg' => '0.5rem',
            'xl' => '0.75rem',
            '2xl' => '1rem',
            'full' => '9999px'
          }
        end

        def get_theme_value(key)
          extend = @theme[:extend] || @theme['extend'] || {}
          base = @theme[key] || @theme[key.to_s] || {}
          extended = extend[key] || extend[key.to_s] || {}

          # Merge base and extended
          merge_theme_values(base, extended)
        end


        def merge_theme_values(base, extended)
          result = base.dup
          extended.each do |key, value|
            if result[key].is_a?(Hash) && value.is_a?(Hash)
              result[key] = merge_theme_values(result[key], value)
            else
              result[key] = value
            end
          end
          result
        end

        # Transform utilities
        def generate_transform_utilities
          # Translate
          translate_values = {
            '0' => '0px',
            '1' => '0.25rem',
            '2' => '0.5rem',
            '3' => '0.75rem',
            '4' => '1rem',
            '6' => '1.5rem',
            '8' => '2rem',
            '12' => '3rem',
            '16' => '4rem',
            '1/2' => '50%',
            '1/3' => '33.333333%',
            '2/3' => '66.666667%',
            '1/4' => '25%',
            'full' => '100%'
          }

          %w[x y].each do |axis|
            translate_values.each do |key, value|
              # Positive translate
              rule = Protocss.rule(selector: ".translate-#{axis}-#{key}")
              rule.append(Protocss.decl(prop: '--tw-translate-' + axis, value: value))
              rule.append(Protocss.decl(prop: 'transform', value: 'translate(var(--tw-translate-x, 0), var(--tw-translate-y, 0)) rotate(var(--tw-rotate, 0)) skewX(var(--tw-skew-x, 0)) skewY(var(--tw-skew-y, 0)) scaleX(var(--tw-scale-x, 1)) scaleY(var(--tw-scale-y, 1))'))
              @utilities << rule

              # Negative translate
              rule = Protocss.rule(selector: ".-translate-#{axis}-#{key}")
              rule.append(Protocss.decl(prop: '--tw-translate-' + axis, value: "calc(#{value} * -1)"))
              rule.append(Protocss.decl(prop: 'transform', value: 'translate(var(--tw-translate-x, 0), var(--tw-translate-y, 0)) rotate(var(--tw-rotate, 0)) skewX(var(--tw-skew-x, 0)) skewY(var(--tw-skew-y, 0)) scaleX(var(--tw-scale-x, 1)) scaleY(var(--tw-scale-y, 1))'))
              @utilities << rule
            end
          end

          # Rotate
          rotate_values = { '0' => '0deg', '1' => '1deg', '2' => '2deg', '3' => '3deg', '6' => '6deg', '12' => '12deg', '45' => '45deg', '90' => '90deg', '180' => '180deg' }
          rotate_values.each do |key, value|
            rule = Protocss.rule(selector: ".rotate-#{key}")
            rule.append(Protocss.decl(prop: '--tw-rotate', value: value))
            rule.append(Protocss.decl(prop: 'transform', value: 'translate(var(--tw-translate-x, 0), var(--tw-translate-y, 0)) rotate(var(--tw-rotate, 0)) skewX(var(--tw-skew-x, 0)) skewY(var(--tw-skew-y, 0)) scaleX(var(--tw-scale-x, 1)) scaleY(var(--tw-scale-y, 1))'))
            @utilities << rule

            rule = Protocss.rule(selector: ".-rotate-#{key}")
            rule.append(Protocss.decl(prop: '--tw-rotate', value: "calc(#{value} * -1)"))
            rule.append(Protocss.decl(prop: 'transform', value: 'translate(var(--tw-translate-x, 0), var(--tw-translate-y, 0)) rotate(var(--tw-rotate, 0)) skewX(var(--tw-skew-x, 0)) skewY(var(--tw-skew-y, 0)) scaleX(var(--tw-scale-x, 1)) scaleY(var(--tw-scale-y, 1))'))
            @utilities << rule
          end

          # Scale
          scale_values = { '0' => '0', '50' => '.5', '75' => '.75', '90' => '.9', '95' => '.95', '100' => '1', '105' => '1.05', '110' => '1.1', '125' => '1.25', '150' => '1.5' }
          scale_values.each do |key, value|
            rule = Protocss.rule(selector: ".scale-#{key}")
            rule.append(Protocss.decl(prop: '--tw-scale-x', value: value))
            rule.append(Protocss.decl(prop: '--tw-scale-y', value: value))
            rule.append(Protocss.decl(prop: 'transform', value: 'translate(var(--tw-translate-x, 0), var(--tw-translate-y, 0)) rotate(var(--tw-rotate, 0)) skewX(var(--tw-skew-x, 0)) skewY(var(--tw-skew-y, 0)) scaleX(var(--tw-scale-x, 1)) scaleY(var(--tw-scale-y, 1))'))
            @utilities << rule
          end

          %w[x y].each do |axis|
            scale_values.each do |key, value|
              rule = Protocss.rule(selector: ".scale-#{axis}-#{key}")
              rule.append(Protocss.decl(prop: "--tw-scale-#{axis}", value: value))
              rule.append(Protocss.decl(prop: 'transform', value: 'translate(var(--tw-translate-x, 0), var(--tw-translate-y, 0)) rotate(var(--tw-rotate, 0)) skewX(var(--tw-skew-x, 0)) skewY(var(--tw-skew-y, 0)) scaleX(var(--tw-scale-x, 1)) scaleY(var(--tw-scale-y, 1))'))
              @utilities << rule
            end
          end

          # Skew
          skew_values = { '0' => '0deg', '1' => '1deg', '2' => '2deg', '3' => '3deg', '6' => '6deg', '12' => '12deg' }
          %w[x y].each do |axis|
            skew_values.each do |key, value|
              rule = Protocss.rule(selector: ".skew-#{axis}-#{key}")
              rule.append(Protocss.decl(prop: "--tw-skew-#{axis}", value: value))
              rule.append(Protocss.decl(prop: 'transform', value: 'translate(var(--tw-translate-x, 0), var(--tw-translate-y, 0)) rotate(var(--tw-rotate, 0)) skewX(var(--tw-skew-x, 0)) skewY(var(--tw-skew-y, 0)) scaleX(var(--tw-scale-x, 1)) scaleY(var(--tw-scale-y, 1))'))
              @utilities << rule

              rule = Protocss.rule(selector: ".-skew-#{axis}-#{key}")
              rule.append(Protocss.decl(prop: "--tw-skew-#{axis}", value: "calc(#{value} * -1)"))
              rule.append(Protocss.decl(prop: 'transform', value: 'translate(var(--tw-translate-x, 0), var(--tw-translate-y, 0)) rotate(var(--tw-rotate, 0)) skewX(var(--tw-skew-x, 0)) skewY(var(--tw-skew-y, 0)) scaleX(var(--tw-scale-x, 1)) scaleY(var(--tw-scale-y, 1))'))
              @utilities << rule
            end
          end
        end

        # Transition utilities
        def generate_transition_utilities
          # Transition property
          transitions = {
            'none' => 'none',
            'all' => 'all',
            'DEFAULT' => 'color, background-color, border-color, text-decoration-color, fill, stroke, opacity, box-shadow, transform, filter, backdrop-filter',
            'colors' => 'color, background-color, border-color, text-decoration-color, fill, stroke',
            'opacity' => 'opacity',
            'shadow' => 'box-shadow',
            'transform' => 'transform'
          }

          transitions.each do |name, value|
            class_name = name == 'DEFAULT' ? 'transition' : "transition-#{name}"
            rule = Protocss.rule(selector: ".#{class_name}")
            rule.append(Protocss.decl(prop: 'transition-property', value: value))
            rule.append(Protocss.decl(prop: 'transition-timing-function', value: 'cubic-bezier(0.4, 0, 0.2, 1)'))
            rule.append(Protocss.decl(prop: 'transition-duration', value: '150ms'))
            @utilities << rule
          end

          # Duration
          durations = { '75' => '75ms', '100' => '100ms', '150' => '150ms', '200' => '200ms', '300' => '300ms', '500' => '500ms', '700' => '700ms', '1000' => '1000ms' }
          durations.each do |key, value|
            rule = Protocss.rule(selector: ".duration-#{key}")
            rule.append(Protocss.decl(prop: 'transition-duration', value: value))
            @utilities << rule
          end

          # Delay
          delays = { '75' => '75ms', '100' => '100ms', '150' => '150ms', '200' => '200ms', '300' => '300ms', '500' => '500ms', '700' => '700ms', '1000' => '1000ms' }
          delays.each do |key, value|
            rule = Protocss.rule(selector: ".delay-#{key}")
            rule.append(Protocss.decl(prop: 'transition-delay', value: value))
            @utilities << rule
          end

          # Timing functions
          easings = {
            'linear' => 'linear',
            'in' => 'cubic-bezier(0.4, 0, 1, 1)',
            'out' => 'cubic-bezier(0, 0, 0.2, 1)',
            'in-out' => 'cubic-bezier(0.4, 0, 0.2, 1)'
          }
          easings.each do |name, value|
            rule = Protocss.rule(selector: ".ease-#{name}")
            rule.append(Protocss.decl(prop: 'transition-timing-function', value: value))
            @utilities << rule
          end
        end

        # Animation utilities
        def generate_animation_utilities
          animations = {
            'none' => 'none',
            'spin' => 'spin 1s linear infinite',
            'ping' => 'ping 1s cubic-bezier(0, 0, 0.2, 1) infinite',
            'pulse' => 'pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite',
            'bounce' => 'bounce 1s infinite'
          }

          animations.each do |name, value|
            rule = Protocss.rule(selector: ".animate-#{name}")
            rule.append(Protocss.decl(prop: 'animation', value: value))
            @utilities << rule
          end

          # Add keyframes
          keyframes = [
            ['spin', 'from { transform: rotate(0deg); } to { transform: rotate(360deg); }'],
            ['ping', '75%, 100% { transform: scale(2); opacity: 0; }'],
            ['pulse', '0%, 100% { opacity: 1; } 50% { opacity: .5; }'],
            ['bounce', '0%, 100% { transform: translateY(-25%); animation-timing-function: cubic-bezier(0.8, 0, 1, 1); } 50% { transform: translateY(0); animation-timing-function: cubic-bezier(0, 0, 0.2, 1); }']
          ]

          keyframes.each do |name, frames|
            at_rule = Protocss.at_rule(name: 'keyframes', params: name)
            # Note: In a full implementation, you'd parse and add the keyframe rules properly
            # For now, we'll add them as raw content
            at_rule.raws[:between] = ' '
            at_rule.raws[:after] = " #{frames} "
            @utilities << at_rule
          end
        end

        # Filter utilities
        def generate_filter_utilities
          # Blur
          blur_values = { 'none' => '0', 'sm' => '4px', 'DEFAULT' => '8px', 'md' => '12px', 'lg' => '16px', 'xl' => '24px', '2xl' => '40px', '3xl' => '64px' }
          blur_values.each do |name, value|
            class_name = name == 'DEFAULT' ? 'blur' : "blur-#{name}"
            rule = Protocss.rule(selector: ".#{class_name}")
            rule.append(Protocss.decl(prop: '--tw-blur', value: "blur(#{value})"))
            rule.append(Protocss.decl(prop: 'filter', value: 'var(--tw-blur) var(--tw-brightness) var(--tw-contrast) var(--tw-grayscale) var(--tw-hue-rotate) var(--tw-invert) var(--tw-saturate) var(--tw-sepia) var(--tw-drop-shadow)'))
            @utilities << rule
          end

          # Brightness
          brightness_values = { '0' => '0', '50' => '.5', '75' => '.75', '90' => '.9', '95' => '.95', '100' => '1', '105' => '1.05', '110' => '1.1', '125' => '1.25', '150' => '1.5', '200' => '2' }
          brightness_values.each do |key, value|
            rule = Protocss.rule(selector: ".brightness-#{key}")
            rule.append(Protocss.decl(prop: '--tw-brightness', value: "brightness(#{value})"))
            rule.append(Protocss.decl(prop: 'filter', value: 'var(--tw-blur) var(--tw-brightness) var(--tw-contrast) var(--tw-grayscale) var(--tw-hue-rotate) var(--tw-invert) var(--tw-saturate) var(--tw-sepia) var(--tw-drop-shadow)'))
            @utilities << rule
          end

          # Contrast
          contrast_values = { '0' => '0', '50' => '.5', '75' => '.75', '100' => '1', '125' => '1.25', '150' => '1.5', '200' => '2' }
          contrast_values.each do |key, value|
            rule = Protocss.rule(selector: ".contrast-#{key}")
            rule.append(Protocss.decl(prop: '--tw-contrast', value: "contrast(#{value})"))
            rule.append(Protocss.decl(prop: 'filter', value: 'var(--tw-blur) var(--tw-brightness) var(--tw-contrast) var(--tw-grayscale) var(--tw-hue-rotate) var(--tw-invert) var(--tw-saturate) var(--tw-sepia) var(--tw-drop-shadow)'))
            @utilities << rule
          end

          # Grayscale
          rule = Protocss.rule(selector: '.grayscale')
          rule.append(Protocss.decl(prop: '--tw-grayscale', value: 'grayscale(100%)'))
          rule.append(Protocss.decl(prop: 'filter', value: 'var(--tw-blur) var(--tw-brightness) var(--tw-contrast) var(--tw-grayscale) var(--tw-hue-rotate) var(--tw-invert) var(--tw-saturate) var(--tw-sepia) var(--tw-drop-shadow)'))
          @utilities << rule

          # Invert
          rule = Protocss.rule(selector: '.invert')
          rule.append(Protocss.decl(prop: '--tw-invert', value: 'invert(100%)'))
          rule.append(Protocss.decl(prop: 'filter', value: 'var(--tw-blur) var(--tw-brightness) var(--tw-contrast) var(--tw-grayscale) var(--tw-hue-rotate) var(--tw-invert) var(--tw-saturate) var(--tw-sepia) var(--tw-drop-shadow)'))
          @utilities << rule

          # Sepia
          rule = Protocss.rule(selector: '.sepia')
          rule.append(Protocss.decl(prop: '--tw-sepia', value: 'sepia(100%)'))
          rule.append(Protocss.decl(prop: 'filter', value: 'var(--tw-blur) var(--tw-brightness) var(--tw-contrast) var(--tw-grayscale) var(--tw-hue-rotate) var(--tw-invert) var(--tw-saturate) var(--tw-sepia) var(--tw-drop-shadow)'))
          @utilities << rule

          # Backdrop filters (similar pattern)
          backdrop_blur_values = { 'none' => '0', 'sm' => '4px', 'DEFAULT' => '8px', 'md' => '12px', 'lg' => '16px', 'xl' => '24px', '2xl' => '40px', '3xl' => '64px' }
          backdrop_blur_values.each do |name, value|
            class_name = name == 'DEFAULT' ? 'backdrop-blur' : "backdrop-blur-#{name}"
            rule = Protocss.rule(selector: ".#{class_name}")
            rule.append(Protocss.decl(prop: '--tw-backdrop-blur', value: "blur(#{value})"))
            rule.append(Protocss.decl(prop: 'backdrop-filter', value: 'var(--tw-backdrop-blur) var(--tw-backdrop-brightness) var(--tw-backdrop-contrast) var(--tw-backdrop-grayscale) var(--tw-backdrop-hue-rotate) var(--tw-backdrop-invert) var(--tw-backdrop-opacity) var(--tw-backdrop-saturate) var(--tw-backdrop-sepia)'))
            @utilities << rule
          end
        end

        # Shadow utilities
        def generate_shadow_utilities
          shadows = {
            'sm' => '0 1px 2px 0 rgb(0 0 0 / 0.05)',
            'DEFAULT' => '0 1px 3px 0 rgb(0 0 0 / 0.1), 0 1px 2px -1px rgb(0 0 0 / 0.1)',
            'md' => '0 4px 6px -1px rgb(0 0 0 / 0.1), 0 2px 4px -2px rgb(0 0 0 / 0.1)',
            'lg' => '0 10px 15px -3px rgb(0 0 0 / 0.1), 0 4px 6px -4px rgb(0 0 0 / 0.1)',
            'xl' => '0 20px 25px -5px rgb(0 0 0 / 0.1), 0 8px 10px -6px rgb(0 0 0 / 0.1)',
            '2xl' => '0 25px 50px -12px rgb(0 0 0 / 0.25)',
            'inner' => 'inset 0 2px 4px 0 rgb(0 0 0 / 0.05)',
            'none' => 'none'
          }

          shadows.each do |name, value|
            class_name = name == 'DEFAULT' ? 'shadow' : "shadow-#{name}"
            rule = Protocss.rule(selector: ".#{class_name}")
            rule.append(Protocss.decl(prop: 'box-shadow', value: value))
            @utilities << rule
          end
        end

        # Opacity utilities
        def generate_opacity_utilities
          (0..100).step(5).each do |opacity|
            rule = Protocss.rule(selector: ".opacity-#{opacity}")
            rule.append(Protocss.decl(prop: 'opacity', value: (opacity / 100.0).to_s))
            @utilities << rule
          end
        end

        # Z-index utilities
        def generate_z_index_utilities
          z_indices = { '0' => '0', '10' => '10', '20' => '20', '30' => '30', '40' => '40', '50' => '50', 'auto' => 'auto' }
          z_indices.each do |key, value|
            rule = Protocss.rule(selector: ".z-#{key}")
            rule.append(Protocss.decl(prop: 'z-index', value: value))
            @utilities << rule
          end
        end

        # Overflow utilities
        def generate_overflow_utilities
          %w[auto hidden visible scroll].each do |value|
            rule = Protocss.rule(selector: ".overflow-#{value}")
            rule.append(Protocss.decl(prop: 'overflow', value: value))
            @utilities << rule
          end

          %w[x y].each do |axis|
            %w[auto hidden visible scroll].each do |value|
              rule = Protocss.rule(selector: ".overflow-#{axis}-#{value}")
              rule.append(Protocss.decl(prop: "overflow-#{axis}", value: value))
              @utilities << rule
            end
          end

          # Object fit
          %w[contain cover fill none scale-down].each do |value|
            rule = Protocss.rule(selector: ".object-#{value}")
            rule.append(Protocss.decl(prop: 'object-fit', value: value))
            @utilities << rule
          end

          # Object position
          positions = { 'bottom' => 'bottom', 'center' => 'center', 'left' => 'left', 'left-bottom' => 'left bottom', 'left-top' => 'left top', 'right' => 'right', 'right-bottom' => 'right bottom', 'right-top' => 'right top', 'top' => 'top' }
          positions.each do |name, value|
            rule = Protocss.rule(selector: ".object-#{name}")
            rule.append(Protocss.decl(prop: 'object-position', value: value))
            @utilities << rule
          end
        end

        # Interactivity utilities
        def generate_interactivity_utilities
          # Cursor
          cursors = %w[auto default pointer wait text move help not-allowed none context-menu progress cell crosshair vertical-text alias copy no-drop grab grabbing all-scroll col-resize row-resize n-resize e-resize s-resize w-resize ne-resize nw-resize se-resize sw-resize ew-resize ns-resize nesw-resize nwse-resize zoom-in zoom-out]
          cursors.each do |cursor|
            rule = Protocss.rule(selector: ".cursor-#{cursor}")
            rule.append(Protocss.decl(prop: 'cursor', value: cursor))
            @utilities << rule
          end

          # Pointer events
          %w[none auto].each do |value|
            rule = Protocss.rule(selector: ".pointer-events-#{value}")
            rule.append(Protocss.decl(prop: 'pointer-events', value: value))
            @utilities << rule
          end

          # Resize
          %w[none both horizontal vertical].each do |value|
            resize_class = value == 'horizontal' ? 'x' : (value == 'vertical' ? 'y' : value)
            rule = Protocss.rule(selector: ".resize-#{resize_class}")
            rule.append(Protocss.decl(prop: 'resize', value: value))
            @utilities << rule
          end

          # User select
          %w[none text all auto].each do |value|
            rule = Protocss.rule(selector: ".select-#{value}")
            rule.append(Protocss.decl(prop: 'user-select', value: value))
            @utilities << rule
          end

          # Appearance
          rule = Protocss.rule(selector: '.appearance-none')
          rule.append(Protocss.decl(prop: 'appearance', value: 'none'))
          @utilities << rule
        end

        # Accessibility utilities
        def generate_accessibility_utilities
          # Screen reader only
          rule = Protocss.rule(selector: '.sr-only')
          rule.append(Protocss.decl(prop: 'position', value: 'absolute'))
          rule.append(Protocss.decl(prop: 'width', value: '1px'))
          rule.append(Protocss.decl(prop: 'height', value: '1px'))
          rule.append(Protocss.decl(prop: 'padding', value: '0'))
          rule.append(Protocss.decl(prop: 'margin', value: '-1px'))
          rule.append(Protocss.decl(prop: 'overflow', value: 'hidden'))
          rule.append(Protocss.decl(prop: 'clip', value: 'rect(0, 0, 0, 0)'))
          rule.append(Protocss.decl(prop: 'white-space', value: 'nowrap'))
          rule.append(Protocss.decl(prop: 'border-width', value: '0'))
          @utilities << rule

          # Not screen reader only
          rule = Protocss.rule(selector: '.not-sr-only')
          rule.append(Protocss.decl(prop: 'position', value: 'static'))
          rule.append(Protocss.decl(prop: 'width', value: 'auto'))
          rule.append(Protocss.decl(prop: 'height', value: 'auto'))
          rule.append(Protocss.decl(prop: 'padding', value: '0'))
          rule.append(Protocss.decl(prop: 'margin', value: '0'))
          rule.append(Protocss.decl(prop: 'overflow', value: 'visible'))
          rule.append(Protocss.decl(prop: 'clip', value: 'auto'))
          rule.append(Protocss.decl(prop: 'white-space', value: 'normal'))
          @utilities << rule
        end
      end
    end
  end
end
