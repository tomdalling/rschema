# frozen_string_literal: true

module RSchema
  module Coercers
    #
    # Coerces `String`s to `Time`s using `Time.parse`
    module Time
      extend self

      def build(_schema)
        self
      end

      def call(value)
        case value
        when ::Time then Result.success(value)
        when ::String then coerce_string(value)
        else Result.failure
        end
      end

      def will_affect?(value)
        !value.is_a?(Time)
      end

      private

      def coerce_string(str)
        time = begin
                 ::Time.parse(str)
               rescue
                 nil
               end
        time ? Result.success(time) : Result.failure
      end
    end
  end
end
