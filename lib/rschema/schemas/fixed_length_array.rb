module RSchema
  module Schemas
    class FixedLengthArray
      attr_reader :subschemas

      def initialize(subschemas)
        @subschemas = subschemas
      end

      def call(value, options=RSchema::Options.default)
        unless value.kind_of?(Array)
          return Result.failure(Error.new(
            symbolic_name: 'rschema/fixed_length_array/not_an_array',
            schema: self,
            value: value,
          ))
        end

        unless value.size == @subschemas.size
          return Result.failure(Error.new(
            symbolic_name: 'rschema/fixed_length_array/incorrect_size',
            schema: self,
            value: value,
          ))
        end

        validate_value, error = apply_subschemas(value, options)
        if error.empty?
          Result.success(validate_value)
        else
          Result.failure(error)
        end
      end

      def apply_subschemas(array_value, options)
        validate_value = []
        errors = {}

        array_value.zip(@subschemas).each_with_index do |(subvalue, subschema), idx|
          result = subschema.call(subvalue, options)
          if result.valid?
            validate_value << result.value
          else
            errors[idx] = result.error
            break if options.fail_fast?
          end
        end

        [validate_value, errors]
      end
    end
  end
end