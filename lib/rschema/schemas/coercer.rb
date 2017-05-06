module RSchema
  module Schemas
    class Coercer
      attr_reader :coercer, :subschema

      def initialize(coercer, subschema)
        @coercer = coercer
        @subschema = subschema
      end

      def call(value, options=RSchema::Options.default)
        result = coercer.call(value)
        if result.valid?
          @subschema.call(result.value, options)
        else
          result.error.is_a?(RSchema::Error) ? result : default_failure(value)
        end
      end

      def default_failure(value)
        return Result.failure(Error.new(
          schema: self,
          value: value,
          symbolic_name: :coercion_failure,
        ))
      end

      def with_wrapped_subschemas(wrapper)
        self.class.new(coercer, wrapper.wrap(subschema))
      end
    end
  end
end
