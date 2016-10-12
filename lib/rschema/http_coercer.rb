module RSchema
  module HTTPCoercer
    def self.wrap(schema)
      coercer_klass = begin
        case schema
        when Schemas::Type then TYPE_COERCERS[schema.type]
        end
      end

      wrapped_schema = schema.with_wrapped_subschemas(self)
      coercer_klass ? coercer_klass.new(wrapped_schema) : wrapped_schema
    end

    class Coercer
      attr_reader :subschema

      def initialize(subschema)
        @subschema = subschema
      end

      def call(value, options=RSchema::Options.default)
        @subschema.call(coerce(value), options)
      rescue CoercionFailed
        return Result.failure(Error.new(
          schema: self,
          value: value,
          symbolic_name: "coercion_failure",
        ))
      end

      def with_wrapped_subschemas(wrapper)
        self.class.new(wrapper.wrap(subschema))
      end

      def invalid!
        raise CoercionFailed
      end

      class CoercionFailed < StandardError; end
    end

    class SymbolCoercer < Coercer
      def coerce(value)
        case value
        when Symbol then value
        when String then value.to_sym
        else invalid!
        end
      end
    end

    class IntegerCoercer < Coercer
      def coerce(value)
        Integer(value)
      rescue ArgumentError
        invalid!
      end
    end

    class FloatCoercer < Coercer
      def coerce(value)
        Float(value)
      rescue ArgumentError
        invalid!
      end
    end

    TYPE_COERCERS = {
      Symbol => SymbolCoercer,
      Integer => IntegerCoercer,
      Float => FloatCoercer,
    }
  end
end
