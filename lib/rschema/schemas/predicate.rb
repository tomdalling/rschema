module RSchema
  module Schemas
    class Predicate
      attr_reader :block

      def initialize(block)
        @block = block
      end

      def call(value, options=Options.default)
        if block.call(value)
          Result.success(value)
        else
          Result.failure(Error.new(
            schema: self,
            value: value,
            symbolic_name: :false,
          ))
        end
      end

      def with_wrapped_subschemas(wrapper)
        self
      end
    end
  end
end
