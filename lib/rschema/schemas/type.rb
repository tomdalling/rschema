module RSchema
  module Schemas
    class Type
      attr_reader :type

      def initialize(type)
        @type = type
      end

      def call(value, options = RSchema::Options.default)
        if value.is_a?(@type)
          Result.success(value)
        else
          Result.failure(Error.new(
            schema: self,
            value: value,
            symbolic_name: 'wrong_type',
          ))
        end
      end

      def with_wrapped_subschemas(wrapper)
        self
      end
    end
  end
end
