# frozen_string_literal: true

module RSchema
  module Coercers
    #
    # Coerces `String`s to `Symbol`s
    #
    module Symbol
      extend self

      def build(_schema)
        self
      end

      def call(value)
        case value
        when ::Symbol then Result.success(value)
        when ::String then Result.success(value.to_sym)
        else Result.failure
        end
      end

      def will_affect?(value)
        !value.is_a?(Symbol)
      end
    end
  end
end
