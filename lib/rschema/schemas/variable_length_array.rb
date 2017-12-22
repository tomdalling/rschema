# frozen_string_literal: true

module RSchema
  module Schemas
    #
    # A schema that matches variable-length arrays, where all elements conform
    # to a single subschema
    #
    # @example A variable-length array schema
    #     schema = RSchema.define { array(_Integer) }
    #     schema.valid?([1,2,3]) #=> true
    #     schema.valid?([]) #=> true
    #
    class VariableLengthArray
      attr_accessor :element_schema

      def initialize(element_schema)
        @element_schema = element_schema
      end

      def call(value, options)
        return type_failure(value) unless Array === value

        accumulate_elements(value, options).to_result
      end

      def with_wrapped_subschemas(wrapper)
        self.class.new(wrapper.wrap(element_schema))
      end

      private

      def type_failure(value)
        Result.failure(
          Error.new(
            schema: self,
            value: value,
            symbolic_name: :not_an_array,
          ),
        )
      end

      def accumulate_elements(array, options)
        Accumulation.new.tap do |accumulator|
          array.each_with_index do |subvalue, idx|
            result = @element_schema.call(subvalue, options)
            accumulator.merge!(result, idx)
            break if options.fail_fast? && accumulator.failed?
          end
        end
      end

      # @!visibility private
      class Accumulation
        def initialize
          @errors = {}
          @values = []
        end

        def merge!(result, idx)
          if result.valid?
            @values[idx] = result.value
          else
            @errors[idx] = result.error
          end
        end

        def failed?
          !@errors.empty?
        end

        def to_result
          if @errors.empty?
            Result.success(@values)
          else
            Result.failure(@errors)
          end
        end
      end
    end
  end
end
