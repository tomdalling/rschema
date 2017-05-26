module RSchema
module Schemas

#
# A schema that matches variable-length arrays, where all elements conform to
# a single subschema
#
# @example A variable-length array schema
#     schema = RSchema.define { array(_Integer) }
#     schema.valid?([1,2,3]) #=> true
#     schema.valid?([]) #=> true
#
class VariableLengthArray
  attr_accessor :element_schema

  def initialize(element_schema)
    @element_schema = element_schema
  end

  def call(value, options)
    if value.kind_of?(Array)
      validated_values, errors = validate_elements(value, options)
      if errors.empty?
        Result.success(validated_values)
      else
        Result.failure(errors)
      end
    else
      Result.failure(Error.new(
        schema: self,
        value: value,
        symbolic_name: :not_an_array,
      ))
    end
  end

  def with_wrapped_subschemas(wrapper)
    self.class.new(wrapper.wrap(element_schema))
  end

  def validate_elements(array, options)
    errors = {}
    validated_values = []

    array.each_with_index do |subvalue, idx|
      result = @element_schema.call(subvalue, options)
      if result.valid?
        validated_values[idx] = result.value
      else
        errors[idx] = result.error
        break if options.fail_fast?
      end
    end

    [validated_values, errors]
  end

end
end
end
