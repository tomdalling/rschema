module RSchema
module Coercers

  module Symbol
    extend self

    def build(schema)
      self
    end

    def call(value)
      case value
      when ::Symbol then Result.success(value)
      when ::String then Result.success(value.to_sym)
      else Result.failure
      end
    end
  end

end
end
