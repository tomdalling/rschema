module RSchema
  module Schemas
    class Coercer
      attr_reader :coercers, :subschema

      def initialize(coercers, subschema)
        @coercers = Array(coercers)
        @subschema = subschema
      end

      def call(value, options=RSchema::Options.default)
        result = coerce(value)
        if result.valid?
          @subschema.call(result.value, options)
        else
          result.error.is_a?(RSchema::Error) ? result : default_failure(value)
        end
      end

      def with_wrapped_subschemas(wrapper)
        self.class.new(coercer, wrapper.wrap(subschema))
      end

      private

        def coerce(value)
          result = Result.success(value)

          coercers.each do |coerc|
            result = coerc.call(result.value)
            break if result.invalid?
          end

          result
        end

        def default_failure(value)
          return Result.failure(Error.new(
            schema: self,
            value: value,
            symbolic_name: :coercion_failure,
          ))
        end
    end
  end
end
