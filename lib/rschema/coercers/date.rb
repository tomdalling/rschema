# frozen_string_literal: true

module RSchema
  module Coercers
    #
    # Coerces strings into `Date` objects using `Date.parse`
    module Date
      extend self

      def build(_schema)
        self
      end

      def call(value)
        case value
        when ::Date then Result.success(value)
        when ::String then coerce_string(value)
        else Result.failure
        end
      end

      def will_affect?(value)
        !value.is_a?(::Date)
      end

      private

      def coerce_string(str)
        date = begin
                 ::Date.parse(str)
               rescue StandardError
                 nil
               end
        date ? Result.success(date) : Result.failure
      end
    end
  end
end
