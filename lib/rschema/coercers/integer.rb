# frozen_string_literal: true

module RSchema
  module Coercers
    #
    # Coerces values to `Integer`s using `Kernel#Integer`
    module Integer
      extend self

      def build(_schema)
        self
      end

      def call(value)
        int = begin
                Integer(value)
              rescue StandardError
                nil
              end
        int ? Result.success(int) : Result.failure
      end

      def will_affect?(value)
        !value.is_a?(Integer)
      end
    end
  end
end
