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

        accumulate_elements(value, options).to_result
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

      def accumulate_elements(value, options)
        Accumulation.new.tap do |accumulation|
          value.each do |key, subvalue|
            key_result = key_schema.call(key, options)
            subvalue_result = value_schema.call(subvalue, options)
            accumulation.merge!(key, key_result, subvalue_result)
            break if options.fail_fast? && accumulation.failed?
          end
        end
      end

      # @!visibility private
      class Accumulation
        def initialize
          @key_errors = {}
          @value_errors = {}
          @validated_hash = {}
          @failed = false
        end

        def merge!(key, key_result, value_result)
          if key_result.invalid?
            @key_errors[key] = key_result.error
            @failed = true
          elsif value_result.invalid?
            @value_errors[key] = value_result.error
            @failed = true
          else
            @validated_hash[key_result.value] = value_result.value
          end
        end

        def failed?
          @failed
        end

        def to_result
          if failed?
            Result.failure(keys: @key_errors, values: @value_errors)
          else
            Result.success(@validated_hash)
          end
        end
      end
    end
  end
end
