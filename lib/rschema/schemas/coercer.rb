# frozen_string_literal: true

module RSchema
  module Schemas
    #
    # A schema that applies a coercer to a value, before passing the coerced
    # value to a subschema.
    #
    # This is not a type of schema that you would typically create yourself.
    # It is used internally to implement RSchema's coercion functionality.
    #
    class Coercer
      attr_reader :coercer, :subschema

      def initialize(coercer, subschema)
        @coercer = coercer
        @subschema = subschema
      end

      def call(value, options)
        @subschema.call(coerce_value(value), options)
      end

      def with_wrapped_subschemas(wrapper)
        self.class.new(coercer, wrapper.wrap(subschema))
      end

      private

      def coerce_value(original_value)
        if coercer.will_affect?(original_value)
          result = coercer.call(original_value)
          if result.valid?
            return result.value
          end
        end

        original_value
      end

    end
  end
end
