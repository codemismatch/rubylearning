# frozen_string_literal: true

module Protocss
  module FromJson
    def self.from_json(json, inputs = nil)
      return json.map { |n| from_json(n) } if json.is_a?(Array)

      own_inputs = json.delete(:inputs) || json.delete('inputs')
      defaults = json

      if own_inputs
        inputs = []
        own_inputs.each do |input|
          input_hydrated = Input.new(input[:css] || input['css'], input)
          inputs << input_hydrated
        end
      end

      if defaults[:nodes] || defaults['nodes']
        nodes = (defaults[:nodes] || defaults['nodes']).map { |n| from_json(n, inputs) }
        defaults[:nodes] = nodes
        defaults.delete('nodes')
      end

      if defaults[:source] || defaults['source']
        source = defaults[:source] || defaults['source']
        input_id = source[:input_id] || source['input_id']
        defaults[:source] = source.reject { |k, _| k == :input_id || k == 'input_id' }
        defaults[:source][:input] = inputs[input_id] if input_id && inputs
        defaults.delete('source')
      end

      case defaults[:type] || defaults['type']
      when 'root'
        Root.new(defaults)
      when 'decl'
        Declaration.new(defaults)
      when 'rule'
        Rule.new(defaults)
      when 'comment'
        Comment.new(defaults)
      when 'atrule'
        AtRule.new(defaults)
      else
        raise StandardError, "Unknown node type: #{defaults[:type] || defaults['type']}"
      end
    end
  end
end
