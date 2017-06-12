module RSchema
module Coercers

  module Date
    extend self

    def build(schema)
      self
    end

    def call(value)
      case value
      when ::Date
        Result.success(value)
      when ::String
        date = ::Date.parse(value) rescue nil
        date ? Result.success(date) : Result.failure
      else
        Result.failure
      end
    end

    def will_affect?(value)
      not value.is_a?(::Date)
    end
  end

end
end
