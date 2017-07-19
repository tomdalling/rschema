# frozen_string_literal: true

require 'set'

module RSchema
  module Schemas
    #
    # A schema that matches `Set` objects (from the Ruby standard library)
    #
    # @example A set of integers
    #     require 'set'
    #     schema = RSchema.define { set(_Integer) }
    #     schema.valid?(Set[1, 2, 3]) #=> true
    #     schema.valid?(Set[:a, :b, :c]) #=> false
    #
    class Set
      attr_reader :subschema

      def initialize(subschema)
        @subschema = subschema
      end

      def call(value, options)
        return not_a_set_result(value) unless value.is_a?(::Set)

        validated_set, errors = apply_subschema(value, options)

        if errors.empty?
          Result.success(validated_set)
        else
          Result.failure(errors)
        end
      end

      def with_wrapped_subschemas(wrapper)
        wrapped_subschema = wrapper.wrap(subschema)
        self.class.new(wrapped_subschema)
      end

      private

      def apply_subschema(set, options)
        validated_set = ::Set.new
        errors = {}

        set.each do |subvalue|
          subresult = subschema.call(subvalue, options)
          if subresult.valid?
            validated_set << subresult.value
          else
            errors[subvalue] = subresult.error
          end
          break if options.fail_fast?
        end

        [validated_set, errors]
      end

      def not_a_set_result(value)
        Result.failure(
          Error.new(
            schema: self,
            symbolic_name: :not_a_set,
            value: value,
          ),
        )
      end
    end
  end
end
