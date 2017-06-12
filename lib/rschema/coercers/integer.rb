module RSchema
module Coercers

  module Integer
    extend self

    def build(schema)
      self
    end

    def call(value)
      int = Integer(value) rescue nil
      int ? Result.success(int) : Result.failure
    end

    def will_affect?(value)
      not value.is_a?(Integer)
    end
  end

end
end
