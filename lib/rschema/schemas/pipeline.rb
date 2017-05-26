module RSchema
module Schemas

#
# A schema that chains together an ordered list of other schemas
#
# @example A schema for positive floats
#     schema = RSchema.define do
#       pipeline(
#         _Float,
#         predicate{ |f| f > 0.0 },
#       )
#     end
#     schema.valid?(6.2) #=> true
#     schema.valid?('hi') #=> false (because it's not a Float)
#     schema.valid?(-6.2) #=> false (because predicate failed)
#
class Pipeline
  attr_reader :subschemas

  def initialize(subschemas)
    @subschemas = subschemas
  end

  def call(value, options)
    result = Result.success(value)

    subschemas.each do |subsch|
      result = subsch.call(result.value, options)
      break if result.invalid?
    end

    result
  end

  def with_wrapped_subschemas(wrapper)
    wrapped_subschemas = subschemas.map{ |ss| wrapper.wrap(ss) }
    self.class.new(wrapped_subschemas)
  end

end
end
end
