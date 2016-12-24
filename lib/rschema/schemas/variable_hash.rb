module RSchema
  module Schemas
    class VariableHash
      attr_reader :key_schema, :value_schema

      def initialize(key_schema, value_schema)
        @key_schema = key_schema
        @value_schema = value_schema
      end

      def call(value, options=Options.default)
        return not_a_hash_result(value) unless value.is_a?(Hash)

        #TODO: this isn't done
        result = {}
        key_errors = {}
        value_errors = {}

        value.each do |key, subvalue|
          key_result = key_schema.call(key, options)
          if key_result.invalid?
            key_errors[key] = key_result.error
            break if options.fail_fast?
          end

          subvalue_result = value_schema.call(subvalue, options)
          if subvalue_result.invalid?
            value_errors[key] = subvalue_result.error
            break if options.fail_fast?
          end

          if key_result.valid? && subvalue_result.valid?
            result[key_result.value] = subvalue_result.value
          end
        end

        if key_errors.empty? && value_errors.empty?
          Result.success(result)
        else
          Result.failure(subschema_error(value, key_errors, value_errors))
        end
      end

      def with_wrapped_subschemas(wrapper)
        self.class.new(
          wrapper.wrap(key_schema),
          wrapper.wrap(value_schema),
        )
      end

      private

        def not_a_hash_result(value)
          Result.failure(Error.new(
            schema: self,
            value: value,
            symbolic_name: 'not_a_hash',
          ))
        end

        def subschema_error(value, key_errors, value_errors)
          Error.new(
            schema: self,
            value: value,
            symbolic_name: 'contents_invalid',
            vars: {
              # TODO: these need to be moved out of :vars.
              #       they should be suberrors in an error hash.
              key_errors: key_errors,
              value_errors: value_errors,
            }
          )
        end
    end
  end
end
