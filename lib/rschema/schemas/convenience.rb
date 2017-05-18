require 'delegate'

module RSchema
module Schemas
class Convenience < SimpleDelegator
  def initialize(raw_schema)
    super
  end

  def raw_schema
    __getobj__
  end

  def validate(value, options=Options.default)
    call(value, options)
  end

  def validate!(value, options=Options.default)
    result = call(value, options)
    if result.valid?
      result.value
    else
      raise RSchema::Invalid.new(result.error)
    end
  end

  def valid?(value)
    result = call(value, Options.new(fail_fast: true))
    result.valid?
  end

  def self.wrap(schema)
    if schema.is_a?(self)
      schema
    else
      new(schema)
    end
  end

  def self.unwrap(schema)
    while schema.is_a?(self)
      schema = schema.raw_schema
    end
    schema
  end

  def with_wrapped_subschemas(wrapper)
    self.class.new(wrapper.wrap(raw_schema))
  end

end
end
end
