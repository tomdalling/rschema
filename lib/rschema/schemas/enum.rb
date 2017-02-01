module RSchema
  module Schemas
    class Enum
      attr_reader :members, :subschema

      def initialize(members, subschema)
        @members = members
        @subschema = subschema
      end

      def call(value, options=Options.default)
        subresult = subschema.call(value, options)
        if subresult.invalid?
          subresult
        elsif members.include?(subresult.value)
          subresult
        else
          Result.failure(Error.new(
            schema: self,
            value: subresult.value,
            symbolic_name: :not_a_member,
          ))
        end
      end

      def with_wrapped_subschemas(wrapper)
        self.class.new(members, wrapper.wrap(subschema))
      end
    end
  end
end
