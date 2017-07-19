# frozen_string_literal: true

module RSchema
  module Schemas
    #
    # A schema that matches only `true` and `false`
    #
    # @example The boolean schema
    #     schema = RSchema.define { boolean }
    #     schema.valid?(true)  #=> true
    #     schema.valid?(false) #=> true
    #     schema.valid?(nil)   #=> false
    #
    class Boolean
      def self.instance
        @instance ||= new
      end

      def call(value, _options)
        if value.equal?(true) || value.equal?(false)
          Result.success(value)
        else
          Result.failure(error(value))
        end
      end

      def with_wrapped_subschemas(_wrapper)
        self
      end

      private

      def error(value)
        Error.new(
          schema: self,
          value: value,
          symbolic_name: :not_a_boolean,
        )
      end
    end
  end
end
