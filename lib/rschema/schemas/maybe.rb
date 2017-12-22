# frozen_string_literal: true

module RSchema
  module Schemas
    #
    # A schema representing that a value may be `nil`
    #
    # If the value is not `nil`, it must conform to the subschema
    #
    # @example A nil-able Integer
    #     schema = RSchema.define{ maybe(_Integer) }
    #     schema.valid?(5) #=> true
    #     schema.valid?(nil) #=> true
    #
    class Maybe
      attr_reader :subschema

      def initialize(subschema)
        @subschema = subschema
      end

      def call(value, options)
        if nil == value
          Result.success(value)
        else
          @subschema.call(value, options)
        end
      end

      def with_wrapped_subschemas(wrapper)
        self.class.new(wrapper.wrap(subschema))
      end
    end
  end
end
