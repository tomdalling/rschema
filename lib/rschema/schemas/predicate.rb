module RSchema
  module Schemas
    class Predicate
      def initialize(validation_proc)
        @validation_proc = validation_proc
      end

      def call(value, options=Options.default)
        if @validation_proc.call(value)
          Result.success(value)
        else
          Result.failure(Error.new(
            schema: self,
            value: value,
            symbolic_name: 'rschema/predicate/false',
          ))
        end
      end

      def with_wrapped_subschemas(wrapper)
        self
      end
    end
  end
end
