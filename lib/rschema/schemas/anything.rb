# frozen_string_literal: true

module RSchema
  module Schemas
    #
    # A schema that matches literally any value
    #
    # @example The anything schema
    #   schema = RSchema.define { anything }
    #   schema.valid?(nil) #=> true
    #   schema.valid?(6.2) #=> true
    #   schema.valid?({ hello: Time.now }) #=> true
    #
    class Anything
      def self.instance
        @instance ||= new
      end

      def call(value, _options)
        Result.success(value)
      end

      def with_wrapped_subschemas(_wrapper)
        self
      end
    end
  end
end
