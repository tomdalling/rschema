module RSchema
module Coercers

  module NilEmptyStrings
    extend self

    def build(schema)
      self
    end

    def call(value)
      if "" == value
        Result.success(nil)
      else
        Result.success(value)
      end
    end

    def will_affect?(value)
      "" == value
    end
  end

end
end
