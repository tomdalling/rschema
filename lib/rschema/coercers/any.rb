# frozen_string_literal: true

module RSchema
  module Coercers
    #
    # Applies subcoercers, in order, until one succeeds
    #
    class Any
      attr_reader :subcoercers

      def self.[](*subbuilders)
        Builder.new(subbuilders)
      end

      def initialize(subcoercers)
        @subcoercers = subcoercers
      end

      def call(value)
        subcoercers.each do |coercer|
          result = coercer.call(value)
          return result if result.valid?
        end
        Result.failure
      end

      def will_affect?(value)
        subcoercers.any? { |sc| sc.will_affect?(value) }
      end

      #
      # Builder for Coercers::Any
      #
      class Builder
        attr_reader :subbuilders

        def initialize(subbuilders)
          @subbuilders = subbuilders
        end

        def build(schema)
          subcoercers = subbuilders.map do |builder|
            builder.build(schema)
          end
          Any.new(subcoercers)
        end
      end
    end
  end
end
