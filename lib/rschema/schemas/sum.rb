module RSchema
module Schemas

#
# A schema that represents a "sum type"
#
# Values must conform to one of the subschemas.
#
# @example A schema that matches both Integers and Strings
#     schema = RSchema.define { either(_String, _Integer) }
#     schema.valid?("hello") #=> true
#     schema.valid?(5) #=> true
#
class Sum
  attr_reader :subschemas

  def initialize(subschemas)
    @subschemas = subschemas
  end

  def call(value, options)
    suberrors = []

    @subschemas.each do |subsch|
      result = subsch.call(value, options)
      if result.valid?
        return result
      else
        suberrors << result.error
      end
    end

    Result.failure(suberrors)
  end

  def with_wrapped_subschemas(wrapper)
    wrapped_subschemas = subschemas.map{ |ss| wrapper.wrap(ss) }
    self.class.new(wrapped_subschemas)
  end

end
end
end
