module RSchema
module Coercers

  module Time
    extend self

    def build(schema)
      self
    end

    def call(value)
      case value
      when ::Time
        Result.success(value)
      when ::String
        time = ::Time.parse(value) rescue nil
        time ? Result.success(time) : Result.failure
      else
        Result.failure
      end
    end
  end

end
end
