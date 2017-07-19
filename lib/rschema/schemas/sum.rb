# frozen_string_literal: true

module RSchema
  module Schemas
    #
    # A schema that represents a "sum type"
    #
    # Values must conform to one of the subschemas.
    #
    # @example A schema that matches both Integers and Strings
    #     schema = RSchema.define { either(_String, _Integer) }
    #     schema.valid?("hello") #=> true
    #     schema.valid?(5) #=> true
    #
    class Sum
      attr_reader :subschemas

      def initialize(subschemas)
        @subschemas = subschemas
      end

      def call(value, options)
        suberrors = []

        @subschemas.each do |ss|
          result = ss.call(value, options)
          return result if result.valid?
          suberrors << result.error
        end

        Result.failure(suberrors)
      end

      def with_wrapped_subschemas(wrapper)
        wrapped_subschemas = subschemas.map { |ss| wrapper.wrap(ss) }
        self.class.new(wrapped_subschemas)
      end
    end
  end
end
