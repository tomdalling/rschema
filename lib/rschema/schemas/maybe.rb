module RSchema
  module Schemas

    class Maybe
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
    end

  end
end
