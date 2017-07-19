# frozen_string_literal: true

module RSchema
  module Coercers
    #
    # Coerces values into `Float` objects using `Kernel#Float`
    #
    module Float
      extend self

      def build(_schema)
        self
      end

      def call(value)
        flt = begin
                Float(value)
              rescue
                nil
              end
        flt ? Result.success(flt) : Result.failure
      end

      def will_affect?(value)
        !value.is_a?(Float)
      end
    end
  end
end
