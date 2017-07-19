# frozen_string_literal: true

module RSchema
  module Coercers
    #
    # Coerces empty strings to `nil`
    #
    module NilEmptyStrings
      extend self

      def build(_schema)
        self
      end

      def call(value)
        if value == ''
          Result.success(nil)
        else
          Result.success(value)
        end
      end

      def will_affect?(value)
        value == ''
      end
    end
  end
end
