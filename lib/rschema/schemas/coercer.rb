module RSchema
module Schemas
class Coercer
  attr_reader :coercer, :subschema

  def initialize(coercer, subschema)
    byebug if coercer.is_a?(Array)
    @coercer = coercer
    @subschema = subschema
  end

  def call(value, options)
    result = coercer.call(value)
    if result.valid?
      @subschema.call(result.value, options)
    else
      failure(value, result.error)
    end
  end

  def with_wrapped_subschemas(wrapper)
    self.class.new(coercer, wrapper.wrap(subschema))
  end

  private

    def failure(value, name)
      return Result.failure(Error.new(
        schema: self,
        value: value,
        symbolic_name: name || :coercion_failure,
      ))
    end

end
end
end
