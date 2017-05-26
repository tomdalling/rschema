require 'delegate'

module RSchema
module Schemas

#
# A wrapper that provides convenience methods for schema objects.
#
# Because this class inherits from `SimpleDelegator`, convenience wrappers
# behave like their underlying schemas. That is, you can call methods on the
# underlying schema object through the convenience wrapper.
#
# Schema objects only need to implement the `call` method to validate values.
# This small interface is simple for schema classes to implement, but not
# very descriptive when actually using the schema objects. So, to make
# schema objects nicer to use, this class provides a variety of
# more-descriptive methods like {#validate}, {#validate!}, {#valid?}, and
# {#invalid?}.
#
class Convenience < SimpleDelegator
  def initialize(underlying_schema)
    super
  end

  # @return [schema] the underlying schema object
  def underlying_schema
    __getobj__
  end

  #
  # Applies the schema to a value
  #
  # This is that same as the `call` method available on all schema objects,
  # except that the `options` param is optional.
  #
  # @param value [Object] The value to validate
  # @param options [RSchema::Options]
  #
  # @return [RSchema::Result]
  #
  def validate(value, options=Options.default)
    call(value, options)
  end

  #
  # Returns the validation error for the given value
  #
  # @param value [Object] The value to validate
  # @param options [RSchema::Options]
  #
  # @return The error object if `value` is invalid, otherwise `nil`.
  #
  # @see Result#error
  #
  def error_for(value, options=Options.default)
    result = underlying_schema.call(value, options)
    if result.valid?
      nil
    else
      result.error
    end
  end

  #
  # Applies the schema to a value, raising an exception if the value is invalid
  #
  # @param value [Object] The value to validate
  # @param options [RSchema::Options]
  #
  # @raise [RSchema::Invalid] If the value is not valid
  # @return [Object] The validated value
  #
  # @see Result#value
  #
  def validate!(value, options=Options.default)
    result = underlying_schema.call(value, options)
    if result.valid?
      result.value
    else
      raise RSchema::Invalid.new(result.error)
    end
  end

  #
  # Checks whether a value is valid or not
  #
  # @param value [Object] The value to validate
  # @return [Boolean] `true` if the value is valid, otherwise `false`
  #
  def valid?(value)
    result = underlying_schema.call(value, Options.fail_fast)
    result.valid?
  end

  #
  # The opposite of {#valid?}
  #
  # @see #valid?
  #
  def invalid?(value)
    not valid?(value)
  end

  #
  # Wraps the given schema in a {Convenience}, if it isn't already wrapped.
  #
  # @param schema [schema] The schema to wrap
  # @return {Convenience}
  #
  def self.wrap(schema)
    if schema.is_a?(self)
      schema
    else
      new(schema)
    end
  end

  #
  # Removes any {Convenience} wrappers from a schema
  #
  # @param schema [schema] The schema to unwrap
  # @return [schema] The underlying schema, with all {Convenience} wrappers
  #   removed
  def self.unwrap(schema)
    while schema.is_a?(self)
      schema = schema.underlying_schema
    end
    schema
  end

  # @!visibility private
  def with_wrapped_subschemas(wrapper)
    self.class.new(wrapper.wrap(underlying_schema))
  end

end
end
end
