require 'set'

module RSchema
  module Schemas
    class Set
      attr_reader :subschema

      def initialize(subschema)
        @subschema = subschema
      end

      def call(value, options=RSchema::Options.default)
        return not_a_set_result(value) unless value.is_a?(::Set)

        result_value = ::Set.new
        result_errors = {}

        value.each do |subvalue|
          subresult = subschema.call(subvalue, options)
          if subresult.valid?
            result_value << subresult.value
          else
            result_errors[subvalue] = subresult.error
          end

          break if options.fail_fast?
        end

        if result_errors.empty?
          Result.success(result_value)
        else
          Result.failure(result_errors)
        end
      end

      def with_wrapped_subschemas(wrapper)
        wrapped_subschema = wrapper.wrap(subschema)
        self.class.new(wrapped_subschema)
      end

      private
        def not_a_set_result(value)
          Result.failure(Error.new(
            schema: self,
            symbolic_name: :not_a_set,
            value: value,
          ))
        end
    end
  end
end
