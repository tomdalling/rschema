module RSchema
module Schemas

#
# A schema that matches `Hash` objects with known keys
#
# @example A typical fixed hash schema
#     schema = RSchema.define do
#       fixed_hash(
#         name: _String,
#         optional(:age) => _Integer,
#       )
#     end
#     schema.valid?({ name: "Tom" }) #=> true
#     schema.valid?({ name: "Dane", age: 55 }) #=> true
#
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

  #
  # Creates a new {FixedHash} schema with the given attributes merged in
  #
  # @param new_attributes [Array<Attribute>] The attributes to merge
  # @return [FixedHash] A new schema with the given attributes merged in
  #
  # @example Merging new attributes into an existing {Schemas::FixedHash} schema
  #     person_schema = RSchema.define_hash {{
  #       name: _String,
  #       age: _Integer,
  #     }}
  #     person_schema.valid?(name: "t", age: 5) #=> true
  #     person_schema.valid?(name: "t", age: 5, id: 3) #=> false
  #
  #     person_with_id_schema = RSchema.define do
  #       person_schema.merge(attributes(
  #         id: _Integer,
  #       ))
  #     end
  #     person_with_id_schema.valid?(name: "t", age: 5, id: 3) #=> true
  #     person_with_id_schema.valid?(name: "t", age: 5) #=> false
  #
  def merge(new_attributes)
    merged_attrs = (attributes + new_attributes)
      .map { |attr| [attr.key, attr] }
      .to_h
      .values

    self.class.new(merged_attrs)
  end

  #
  # Creates a new {FixedHash} schema with the given attributes removed
  #
  # @param attribute_keys [Array<Object>] The keys to remove
  # @return [FixedHash] A new schema with the given attributes removed
  #
  # @example Removing an attribute
  #     cat_and_dog = RSchema.define_hash {{
  #       dog: _String,
  #       cat: _String,
  #     }}
  #
  #     only_cat = RSchema.define { cat_and_dog.without(:dog) }
  #     only_cat.valid?({ cat: 'meow' }) #=> true
  #     only_cat.valid?({ cat: 'meow', dog: 'woof' }) #=> false
  #
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

  def failure_error(subresults)
    subresults
      .select{ |_, result| result.invalid? }
      .map{ |key, result| [key, result.error] }
      .to_h
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
