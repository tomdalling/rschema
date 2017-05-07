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
  end

end
end
