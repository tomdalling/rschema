module RSchema
  module Schemas

    class Boolean
      def self.instance
        @instance ||= new
      end

      def call(value, options=Options.default)
        if value.equal?(true) || value.equal?(false)
          Result.success(value)
        else
          Result.failure(Error.new(
            schema: self,
            value: value,
            symbolic_name: :not_a_boolean,
          ))
        end
      end

      def with_wrapped_subschemas(wrapper)
        self
      end
    end

  end
end
