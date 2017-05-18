module RSchema
module Schemas
class FixedHash
  attr_reader :attributes

  def initialize(attributes)
    @attributes = attributes
  end

  def call(value, options)
    return not_a_hash_result(value) unless value.is_a?(Hash)
    return missing_attrs_result(value) if missing_keys(value).any?
    return extraneous_attrs_result(value) if extraneous_keys(value).any?

    subresults = attr_subresults(value, options)
    if subresults.values.any?(&:invalid?)
      Result.failure(failure_error(subresults))
    else
      Result.success(success_value(subresults))
    end
  end

  def with_wrapped_subschemas(wrapper)
    wrapped_attributes = attributes.map do |attr|
      attr.with_wrapped_value_schema(wrapper)
    end

    self.class.new(wrapped_attributes)
  end

  def [](attr_key)
    attributes.find{ |attr| attr.key == attr_key }
  end

  def merge(new_attributes)
    merged_attrs = (attributes + new_attributes)
      .map { |attr| [attr.key, attr] }
      .to_h
      .values

    self.class.new(merged_attrs)
  end

  def without(attribute_keys)
    filtered_attrs = attributes
      .reject { |attr| attribute_keys.include?(attr.key) }

    self.class.new(filtered_attrs)
  end

  Attribute = Struct.new(:key, :value_schema, :optional) do
    def with_wrapped_value_schema(wrapper)
      self.class.new(key, wrapper.wrap(value_schema), optional)
    end
  end

  private

  def missing_keys(value)
    attributes
      .reject(&:optional)
      .map(&:key)
      .reject{ |k| value.has_key?(k) }
  end

  def missing_attrs_result(value)
    Result.failure(Error.new(
      schema: self,
      value: value,
      symbolic_name: :missing_attributes,
      vars: {
        missing_keys: missing_keys(value),
      }
    ))
  end

  def extraneous_keys(value)
    allowed_keys = attributes.map(&:key)
    value.keys.reject{ |k| allowed_keys.include?(k) }
  end

  def extraneous_attrs_result(value)
    Result.failure(Error.new(
      schema: self,
      value: value,
      symbolic_name: :extraneous_attributes,
      vars: {
        extraneous_keys: extraneous_keys(value),
      },
    ))
  end

  def attr_subresults(value, options)
    subresults_by_key = {}

    @attributes.map do |attr|
      if value.has_key?(attr.key)
        subresult = attr.value_schema.call(value[attr.key], options)
        subresults_by_key[attr.key] = subresult
        break if subresult.invalid? && options.fail_fast?
      end
    end

    subresults_by_key
  end

  def failure_error(results)
    error = {}

    results.each do |key, attr_result|
      if attr_result.invalid?
        error[key] = attr_result.error
      end
    end

    error
  end

  def success_value(subresults)
    subresults
      .map{ |key, attr_result| [key, attr_result.value] }
      .to_h
  end

  def not_a_hash_result(value)
    Result.failure(
      Error.new(
        schema: self,
        value: value,
        symbolic_name: :not_a_hash,
      )
    )
  end
end

end
end
