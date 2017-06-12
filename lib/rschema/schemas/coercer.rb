module RSchema
module Schemas

#
# A schema that applies a coercer to a value, before passing the coerced
# value to a subschema.
#
# This is not a type of schema that you would typically create yourself.
# It is used internally to implement RSchema's coercion functionality.
#
class Coercer
  attr_reader :coercer, :subschema

  def initialize(coercer, subschema)
    byebug if coercer.is_a?(Array)
    @coercer = coercer
    @subschema = subschema
  end

  def call(value, options)
    unless coercer.will_affect?(value)
      # short-circuit the coercer
      return @subschema.call(value, options)
    end

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
