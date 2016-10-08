module RSchema
  module Schemas
    class Maybe
      attr_reader :subschema

      def initialize(subschema)
        @subschema = subschema
      end

      def call(value, options=Options.default)
        if value == nil
          Result.success(value)
        else
          @subschema.call(value, options)
        end
      end

      def with_wrapped_subschemas(wrapper)
        self.class.new(wrapper.wrap(subschema))
      end
    end
  end
end
