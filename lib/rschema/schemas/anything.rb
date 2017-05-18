module RSchema
module Schemas
class Anything

  def self.instance
    @instance ||= new
  end

  def call(value, options)
    Result.success(value)
  end

  def with_wrapped_subschemas(wrapper)
    self
  end

end
end
end
