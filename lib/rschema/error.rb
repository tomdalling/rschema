module RSchema
  class Error
    attr_reader :schema, :value, :symbolic_name, :vars

    def initialize(schema:, value:, symbolic_name:, vars: nil)
      @schema = schema
      @value = value
      @symbolic_name = symbolic_name
      @vars = vars
      freeze
    end

    def to_s(detailed=false)
      if detailed
        <<~EOS
          Error: #{symbolic_name}
          Schema: #{schema.class.name}
          Value: #{value.inspect}
          Vars: #{vars.inspect}
        EOS
      else
        "Error #{schema.class}/#{symbolic_name} for value: #{value.inspect}"
      end
    end

    def to_json
      {
        schema: schema.class.name,
        error: symbolic_name.to_s,
        value: jsonify(value),
        vars: jsonify(vars),
      }
    end

    private

      def jsonify(value)
        case value
        when String, Symbol, Numeric, TrueClass, FalseClass, NilClass then value
        when Array then value.map{ |element| jsonify(element) }
        when Hash then value.map{ |k, v| [jsonify(k), jsonify(v)] }.to_h
        else String(value)
        end
      end
  end
end
