module RSchema
  module Schemas
    class Sum
      attr_reader :subschemas

      def initialize(subschemas)
        @subschemas = subschemas
      end

      def call(value, options=Options.default)
        suberrors = {}

        @subschemas.each do |subsch|
          result = subsch.call(value, options)
          if result.valid?
            return result
          else
            suberrors[subsch] = result.error
          end
        end

        Result.failure(suberrors)
      end

      def with_wrapped_subschemas(wrapper)
        wrapped_subschemas = subschemas.map{ |ss| wrapper.wrap(ss) }
        self.class.new(wrapped_subschemas)
      end
    end
  end
end
