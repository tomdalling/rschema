module RSchema
module Schemas

#
# A schema that uses a given block to determine whether a value is valid
#
# @example A predicate that checks if numbers are odd
#     schema = RSchema.define do
#       predicate('odd'){ |x| x.odd? }
#     end
#     schema.valid?(5) #=> true
#     schema.valid?(6) #=> false
#
class Predicate
  attr_reader :block, :name

  def initialize(name = nil, &block)
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
