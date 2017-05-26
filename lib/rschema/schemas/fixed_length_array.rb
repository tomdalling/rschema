module RSchema
module Schemas

#
# A schema that represents an array of fixed length
#
# Each element in the fixed-length array has its own subschema
#
# @example A fixed-length array schema
#     schema = RSchema.define { array(_Integer, _String) }
#     schema.valid?([5, "hello"]) #=> true
#     schema.valid?([5]) #=> false
#     schema.valid?([5, "hello", "world"]) #=> false
#
class FixedLengthArray
  attr_reader :subschemas

  def initialize(subschemas)
    @subschemas = subschemas
  end

  def call(value, options)
    unless value.kind_of?(Array)
      return Result.failure(Error.new(
        symbolic_name: :not_an_array,
        schema: self,
        value: value,
      ))
    end

    unless value.size == @subschemas.size
      return Result.failure(Error.new(
        symbolic_name: :incorrect_size,
        schema: self,
        value: value,
      ))
    end

    validate_value, error = apply_subschemas(value, options)
    if error.empty?
      Result.success(validate_value)
    else
      Result.failure(error)
    end
  end

  def with_wrapped_subschemas(wrapper)
    wrapped_subschemas = subschemas.map{ |ss| wrapper.wrap(ss) }
    self.class.new(wrapped_subschemas)
  end

  private

  def apply_subschemas(array_value, options)
    validate_value = []
    errors = {}

    array_value.zip(@subschemas).each_with_index do |(subvalue, subschema), idx|
      result = subschema.call(subvalue, options)
      if result.valid?
        validate_value << result.value
      else
        errors[idx] = result.error
        break if options.fail_fast?
      end
    end

    [validate_value, errors]
  end
end
end
end
