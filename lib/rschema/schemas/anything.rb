module RSchema
  module Schemas
    class Anything
      def self.instance
        @instance ||= new
      end

      def call(value, options=Options.default)
        Result.success(value)
      end
    end
  end
end
