# frozen_string_literal: true

module RSchema
  module Schemas
    #
    # A schema that matches variable-sized `Hash` objects, where the keys are
    # _not_ known ahead of time.
    #
    # @example A hash of integers to strings
    #     schema = RSchema.define { variable_hash(_Integer => _String) }
    #     schema.valid?({ 5 => "hello", 7 => "world" }) #=> true
    #     schema.valid?({}) #=> true
    #
    class VariableHash
      attr_reader :key_schema, :value_schema

      def initialize(key_schema, value_schema)
        @key_schema = key_schema
        @value_schema = value_schema
      end

      def call(value, options)
        return not_a_hash_result(value) unless value.is_a?(Hash)

        validated_hash, key_errors, value_errors = apply_subschemas(value, options)

        if key_errors.empty? && value_errors.empty?
          Result.success(validated_hash)
        else
          Result.failure(keys: key_errors, values: value_errors)
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
        Result.failure(
          Error.new(
            schema: self,
            value: value,
            symbolic_name: :not_a_hash,
          ),
        )
      end

      def apply_subschemas(value, options)
        validated_hash = {}
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
            validated_hash[key_result.value] = subvalue_result.value
          end
        end

        [validated_hash, key_errors, value_errors]
      end
    end
  end
end
