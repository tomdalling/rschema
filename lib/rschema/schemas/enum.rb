module RSchema
  module Schemas
    class Enum
      attr_reader :members

      def initialize(members)
        @members = members
      end

      def call(value, options=Options.default)
        if members.include?(value)
          Result.success(value)
        else
          Result.failure(Error.new(
            schema: self,
            value: value,
            symbolic_name: 'not_a_member',
          ))
        end
      end

      def with_wrapped_subschemas(wrapper)
        self
      end
    end
  end
end
