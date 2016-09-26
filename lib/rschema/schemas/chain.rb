module RSchema
  module Schemas
    class Chain
      def initialize(subschemas)
        @subschemas = subschemas
      end

      def call(value, options=Options.default)
        result = Result.success(value)

        @subschemas.each do |subsch|
          result = subsch.call(result.value, options)
          break if result.invalid?
        end

        result
      end
    end
  end
end
