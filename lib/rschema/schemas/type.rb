module RSchema
module Schemas

#
# A schema that matches values of a given type (i.e. `value.is_a?(type)`)
#
# @example An Integer schema
#     schema = RSchema.define { _Integer }
#     schema.valid?(5) #=> true
#
# @example A namespaced type
#     schema = RSchema.define do
#       # This will not work:
#       # _ActiveWhatever::Thing
#
#       # This will work:
#       type(ActiveWhatever::Thing)
#     end
#
class Type
  attr_reader :type

  def initialize(type)
    @type = type
  end

  def call(value, options)
    if value.is_a?(@type)
      Result.success(value)
    else
      Result.failure(Error.new(
        schema: self,
        value: value,
        symbolic_name: :wrong_type,
      ))
    end
  end

  def with_wrapped_subschemas(wrapper)
    self
  end

end
end
end
