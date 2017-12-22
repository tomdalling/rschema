# frozen_string_literal: true

module RSchema
  module Schemas
    #
    # A schema that represents an array of fixed length
    #
    # Each element in the fixed-length array has its own subschema
    #
    # @example A fixed-length array schema
    #     schema = RSchema.define { array(_Integer, _String) }
    #     schema.valid?([5, "hello"]) #=> true
    #     schema.valid?([5]) #=> false
    #     schema.valid?([5, "hello", "world"]) #=> false
    #
    class FixedLengthArray
      attr_reader :subschemas

      def initialize(subschemas)
        @subschemas = subschemas
      end

      def call(value, options)
        return type_failure(value) unless ::Array === value
        return size_failure(value) unless value.size == @subschemas.size

        accumulate_elements(value, options).to_result
      end

      def with_wrapped_subschemas(wrapper)
        wrapped_subschemas = subschemas.map { |ss| wrapper.wrap(ss) }
        self.class.new(wrapped_subschemas)
      end

      private

      def accumulate_elements(array, options)
        Accumulation.new.tap do |accumulation|
          array.zip(@subschemas).each_with_index do |(subvalue, subschema), idx|
            result = subschema.call(subvalue, options)
            accumulation.merge!(result, idx)
            break if options.fail_fast? && accumulation.failed?
          end
        end
      end

      def type_failure(value)
        Result.failure(
          Error.new(
            symbolic_name: :not_an_array,
            schema: self,
            value: value,
          ),
        )
      end

      def size_failure(value)
        Result.failure(
          Error.new(
            symbolic_name: :incorrect_size,
            schema: self,
            value: value,
          ),
        )
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
          if failed?
            Result.failure(@errors)
          else
            Result.success(@values)
          end
        end
      end
    end
  end
end
