module RSchema
module Coercers

  class Chain
    attr_reader :subcoercers

    def self.[](*subbuilders)
      Builder.new(subbuilders)
    end

    def initialize(subcoercers)
      @subcoercers = subcoercers
    end

    def call(value)
      result = Result.success(value)
      subcoercers.each do |coercer|
        result = coercer.call(result.value)
        break if result.invalid?
      end
      result
    end

    def will_affect?(value)
      subcoercers.any? { |sc| sc.will_affect?(value) }
    end

    class Builder
      attr_reader :subbuilders

      def initialize(subbuilders)
        @subbuilders = subbuilders
      end

      def build(schema)
        subcoercers = subbuilders.map do |builder|
          builder.build(schema)
        end
        Chain.new(subcoercers)
      end
    end
  end

end
end
