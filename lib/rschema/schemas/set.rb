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
        return not_a_set_result(value) unless ::Set === value

        accumulate_elements(value, options).to_result
      end

      def with_wrapped_subschemas(wrapper)
        wrapped_subschema = wrapper.wrap(subschema)
        self.class.new(wrapped_subschema)
      end

      private

      def accumulate_elements(set, options)
        Accumulation.new.tap do |accumulation|
          set.each do |subvalue|
            subresult = subschema.call(subvalue, options)
            accumulation.merge!(subresult, subvalue)
            break if options.fail_fast? && accumulation.failed?
          end
        end
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

      # @!visibility private
      class Accumulation
        def initialize
          @set = ::Set.new
          @errors = {}
        end

        def merge!(result, element)
          if result.valid?
            @set << result.value
          else
            @errors[element] = result.error
          end
        end

        def failed?
          !@errors.empty?
        end

        def to_result
          if failed?
            Result.failure(@errors)
          else
            Result.success(@set)
          end
        end
      end
    end
  end
end
