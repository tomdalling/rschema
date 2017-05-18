module RSchema
module Schemas
class Predicate
  attr_reader :block, :name

  def initialize(block, name = nil)
    @block = block
    @name = name
  end

  def call(value, options)
    if block.call(value)
      Result.success(value)
    else
      Result.failure(Error.new(
        schema: self,
        value: value,
        symbolic_name: :false,
        vars: { predicate_name: name }
      ))
    end
  end

  def with_wrapped_subschemas(wrapper)
    self
  end

end
end
end
