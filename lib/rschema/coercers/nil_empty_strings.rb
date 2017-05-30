module RSchema
module Coercers

  module NilEmptyStrings
    extend self

    def build(schema)
      self
    end

    def call(value)
      if value.is_a?(String) && value.empty?
        Result.success(nil)
      else
        Result.success(value)
      end
    end
  end

end
end
