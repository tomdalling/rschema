module RSchema
  module Schemas
    class Enum
      def initialize(valid_values)
        @valid_values = valid_values
      end

      def call(value, options=Options.default)
        if @valid_values.include?(value)
          Result.success(value)
        else
          Result.failure(Error.new(
            schema: self,
            value: value,
            symbolic_name: 'rschema/enum/not_a_member',
          ))
        end
      end

      def with_wrapped_subschemas(wrapper)
        self
      end
    end
  end
end
