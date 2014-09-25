require 'set'

module RSchema
  InvalidSchemaError = Class.new(StandardError)
  ValidationFailedError = Class.new(StandardError)
  OptionalHashKey = Struct.new(:key)
  ErrorDetails = Struct.new(:details) do
    def to_s; inspect; end
    def inspect; details.inspect; end
  end

  def self.schema(&block)
    DSL.instance_exec(&block)
  end

  def self.validate(schema, value)
    not walk(schema, value).is_a?(RSchema::ErrorDetails)
  end

  def self.validate!(schema, value)
    result = walk(schema, value)
    raise(ValidationFailedError, result) if result.is_a?(RSchema::ErrorDetails)
    result
  end

  def self.coerce(schema, value)
    result = walk(schema, value, CoercionMapper)
    result.is_a?(RSchema::ErrorDetails) ? nil : result
  end

  def self.coerce!(schema, value)
    result = walk(schema, value, CoercionMapper)
    raise(ValidationFailedError, result) if result.is_a?(RSchema::ErrorDetails)
    result
  end

  def self.walk(schema, value, mapper = nil)
    raise(InvalidSchemaError, schema) unless schema.respond_to?(:schema_walk)
    value = mapper.prewalk(schema, value) if mapper
    value = schema.schema_walk(value, mapper)
    value = mapper.postwalk(schema, value) if mapper
    value
  end
end

module RSchema
  module DSL
    def self._?(key)
      OptionalHashKey.new(key)
    end

    def self.hash_of(subschemas_hash)
      raise InvalidSchemaError unless subschemas_hash.size == 1
      GenericHashSchema.new(subschemas_hash.keys.first, subschemas_hash.values.first)
    end

    def self.set_of(subschema)
      GenericSetSchema.new(subschema)
    end

    def self.predicate(name = nil, &block)
      raise InvalidSchemaError unless block
      PredicateSchema.new(name, block)
    end

    def self.maybe(subschema)
      MaybeSchema.new(subschema)
    end

    def self.enum(possible_values, subschema = nil)
      EnumSchema.new(Set.new(possible_values), subschema)
    end
  end
end

module RSchema
  module CoercionMapper
    def self.prewalk(schema, value)
      if schema == Integer && value.is_a?(String)
        try_convert(value) { Integer(value) }
      elsif schema == Float && value.is_a?(String)
        try_convert(value) { Float(value) }
      elsif schema == Symbol && value.is_a?(String)
        value.to_sym
      elsif schema == String && value.is_a?(Symbol)
        value.to_s
      elsif schema == Array && value.is_a?(Set)
        value.to_a
      elsif (schema == Set || schema.is_a?(GenericSetSchema)) && value.is_a?(Array)
        Set.new(value)
      else
        value
      end
    end

    def self.postwalk(schema, value)
      value
    end

    def self.try_convert(x)
      yield x
    rescue
      x
    end
  end
end

class Class
  def schema_walk(value, mapper)
    if value.is_a?(self)
      value
    else
      RSchema::ErrorDetails.new("is not a #{self}")
    end
  end
end

class Array
  def schema_walk(value, mapper)
    fixed_size = (size != 1)

    if not value.is_a?(Array)
      RSchema::ErrorDetails.new("is not an Array")
    elsif fixed_size && value.size != size
      RSchema::ErrorDetails.new("does not have #{size} elements")
    else
      value.each.with_index.map do |subvalue, idx|
        subschema = (fixed_size ? self[idx] : first )
        subvalue_walked = RSchema.walk(subschema, subvalue, mapper)
        if subvalue_walked.is_a?(RSchema::ErrorDetails)
          break RSchema::ErrorDetails.new({ idx => subvalue_walked.details })
        end
        subvalue_walked
      end
    end
  end
end

class Hash
  #TODO: move out of Hash class

  def schema_walk(value, mapper)
    # must be a hash
    if not value.is_a?(Hash)
      return RSchema::ErrorDetails.new('is not a Hash')
    end

    # extract details from the schema
    required_keys = Set.new
    all_subschemas = {}
    each do |(k, subschema)|
      if k.is_a?(RSchema::OptionalHashKey)
        all_subschemas[k.key] = subschema
      else
        required_keys << k
        all_subschemas[k] = subschema
      end
    end

    # check for extra keys that shouldn't be there
    extraneous = value.keys.reject{ |k| all_subschemas.has_key?(k) }
    if extraneous.size > 0
      return RSchema::ErrorDetails.new({"has extraneous keys" => extraneous})
    end

    # check for required keys that are missing
    missing_requireds = required_keys.reject{ |k| value.has_key?(k) }
    if missing_requireds.size > 0
      return RSchema::ErrorDetails.new({"is missing required keys" => missing_requireds})
    end

    # walk the subvalues
    value.reduce({}) do |accum, (k, subvalue)|
      subvalue_walked = RSchema.walk(all_subschemas[k], subvalue, mapper)
      if subvalue_walked.is_a?(RSchema::ErrorDetails)
        break RSchema::ErrorDetails.new({ k => subvalue_walked.details })
      end
      accum[k] = subvalue_walked
      accum
    end
  end
end

module RSchema
  GenericHashSchema = Struct.new(:key_subschema, :value_subschema) do
    def schema_walk(value, mapper)
      if not value.is_a?(Hash)
        return RSchema::ErrorDetails.new('is not a Hash')
      end

      value.reduce({}) do |accum, (k, v)|
        # walk key
        k_walked = RSchema.walk(key_subschema, k, mapper)
        if k_walked.is_a?(RSchema::ErrorDetails)
          break RSchema::ErrorDetails.new({'has invalid key, where'  => k_walked.details})
        end

        # walk value
        v_walked = RSchema.walk(value_subschema, v, mapper)
        if v_walked.is_a?(RSchema::ErrorDetails)
          break RSchema::ErrorDetails.new({k => v_walked.details})
        end

        accum[k_walked] = v_walked
        accum
      end
    end
  end

  GenericSetSchema = Struct.new(:subschema) do
    def schema_walk(value, mapper)
      if not value.is_a?(Set)
        return RSchema::ErrorDetails.new('is not a Set')
      end

      value.reduce(Set.new) do |accum, subvalue|
        subvalue_walked = RSchema.walk(subschema, subvalue, mapper)

        if subvalue_walked.is_a?(RSchema::ErrorDetails)
          break RSchema::ErrorDetails.new(Set.new([subvalue_walked.details]))
        end

        accum << subvalue_walked
        accum
      end
    end
  end

  PredicateSchema = Struct.new(:name, :block) do
    def schema_walk(value, mapper)
      if block.call(value)
        value
      else
        RSchema::ErrorDetails.new('fails predicate' + (name ? ": #{name}" : ''))
      end
    end
  end

  MaybeSchema = Struct.new(:subschema) do
    def schema_walk(value, mapper)
      if value.nil?
        value
      else
        RSchema.walk(subschema, value, mapper)
      end
    end
  end

  EnumSchema = Struct.new(:value_set, :subschema) do
    def schema_walk(value, mapper)
      value_walked = if subschema
        RSchema.walk(subschema, value, mapper)
      else
        value
      end

      if value_set.include?(value_walked)
        value_walked
      else
        RSchema::ErrorDetails.new('is not a valid enum member')
      end
    end
  end
end

