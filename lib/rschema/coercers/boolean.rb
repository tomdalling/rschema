# frozen_string_literal: true

module RSchema
  module Coercers
    #
    # Coerces certain strings, and nil, to true or false
    #
    module Boolean
      extend self

      TRUTHY_STRINGS = %w[on 1 true yes].freeze
      FALSEY_STRINGS = %w[off 0 false no].freeze

      def build(_schema)
        self
      end

      def call(value)
        case value
        when true, false then Result.success(value)
        when nil then Result.success(false)
        when String then coerce_string(value)
        else Result.failure
        end
      end

      def will_affect?(value)
        value != true && value != false
      end

      private

      def coerce_string(str)
        if TRUTHY_STRINGS.include?(str.downcase)
          Result.success(true)
        elsif FALSEY_STRINGS.include?(str.downcase)
          Result.success(false)
        else
          Result.failure
        end
      end
    end
  end
end
