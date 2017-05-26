module RSchema
module Schemas

#
# A schema that matches a values in a given set.
#
# @example Rock-Paper-Scissors values
#     schema = RSchema.define { enum([:rock, :paper, :scissors]) }
#     schema.valid?(:rock)  #=> true
#     schema.valid?(:paper) #=> true
#     schema.valid?(:gun)   #=> false
#
class Enum
  attr_reader :members, :subschema

  def initialize(members, subschema)
    @members = members
    @subschema = subschema
  end

  def call(value, options)
    subresult = subschema.call(value, options)
    if subresult.invalid?
      subresult
    elsif members.include?(subresult.value)
      subresult
    else
      Result.failure(Error.new(
        schema: self,
        value: subresult.value,
        symbolic_name: :not_a_member,
      ))
    end
  end

  def with_wrapped_subschemas(wrapper)
    self.class.new(members, wrapper.wrap(subschema))
  end
end
end
end
