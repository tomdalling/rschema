module RSchema
module Coercers

  module Float
    extend self

    def build(schema)
      self
    end

    def call(value)
      flt = Float(value) rescue nil
      flt ? Result.success(flt) : Result.failure
    end

    def will_affect?(value)
      not value.is_a?(Float)
    end
  end

end
end
