module RSchema
  module Schemas
    class Alternation
      def initialize(subschemas)
        @subschemas = subschemas
      end

      def call(value, options=Options.default)
        #TODO: this isn't done

        @subschemas.each do |subsch|
          result = subsch.call(value, options)
          if result.valid?
            return result
          end
        end

        Result.failure(Error.new(
          schema: self,
          value: value,
          symbolic_name: 'rschema/alternation/all_invalid',
        ))
      end
    end
  end
end
