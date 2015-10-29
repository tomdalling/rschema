require 'set'

module RSchema
  InvalidSchemaError = Class.new(StandardError)
  ValidationError = Class.new(StandardError)
  OptionalHashKey = Struct.new(:key)
  ErrorDetails = Struct.new(:failing_value, :reason, :key_path) do
    def initialize(failing_value, reason, key_path = [])
      super(failing_value, reason, key_path)
    end

    def to_s
      prefix = (key_path.empty? ?  'The root value' : "The value at #{key_path.inspect}")
      "#{prefix} #{reason}: #{failing_value.inspect}"
    end

    def extend_key_path(key)
      key_path.unshift(key)
      self
    end
  end

  def self.schema(dsl=RSchema::DSL, &block)
    dsl.instance_exec(&block)
  end

  def self.validation_error(schema, value)
    _, error = walk(schema, value)
    error
  end

  def self.validate!(schema, value)
    result, error = walk(schema, value)
    if error.nil?
      result
    else
      raise(ValidationError, error)
    end
  end

  def self.validate(schema, value)
    validation_error(schema, value).nil?
  end

  def self.coerce(schema, value)
    walk(schema, value, CoercionMapper)
  end

  def self.coerce!(schema, value)
    result, error = walk(schema, value, CoercionMapper)
    if error.nil?
      result
    else
      raise(ValidationError, error)
    end
  end

  def self.walk(schema, value, mapper = nil)
    raise(InvalidSchemaError, schema) unless schema.respond_to?(:schema_walk)
    value = mapper.prewalk(schema, value) if mapper
    value = schema.schema_walk(value, mapper)
    value = mapper.postwalk(schema, value) if mapper

    if value.is_a?(RSchema::ErrorDetails)
      [nil, value]
    else
      [value, nil]
    end
  end

  module DSL
    module Base
      def optional(key)
        OptionalHashKey.new(key)
      end
      alias_method :_?, :optional

      def hash_of(subschemas_hash)
        raise InvalidSchemaError unless subschemas_hash.size == 1
        GenericHashSchema.new(subschemas_hash.keys.first, subschemas_hash.values.first)
      end

      def set_of(subschema)
        GenericSetSchema.new(subschema)
      end

      def predicate(name = nil, &block)
        raise InvalidSchemaError unless block
        PredicateSchema.new(name, block)
      end

      def maybe(subschema)
        raise InvalidSchemaError unless subschema
        MaybeSchema.new(subschema)
      end

      def enum(possible_values, subschema = nil)
        raise InvalidSchemaError unless possible_values && possible_values.size > 0
        EnumSchema.new(Set.new(possible_values), subschema)
      end

      def boolean
        BooleanSchema
      end

      def any
        AnySchema
      end
    end
    extend Base
  end

  module CoercionMapper
    def self.prewalk(schema, value)
      if schema == Integer && value.is_a?(String)
        try_convert(value) { Integer(value) }
      elsif schema == Float && value.is_a?(String)
        try_convert(value) { Float(value) }
      elsif schema == Float && value.is_a?(Integer)
        value.to_f
      elsif schema == Symbol && value.is_a?(String)
        value.to_sym
      elsif schema == String && value.is_a?(Symbol)
        value.to_s
      elsif schema == Array && value.is_a?(Set)
        value.to_a
      elsif (schema == Set || schema.is_a?(GenericSetSchema)) && value.is_a?(Array)
        Set.new(value)
      elsif(schema.is_a?(Hash) && value.is_a?(Hash))
        coerce_hash(schema, value)
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

    def self.coerce_hash(schema, value)
      symbol_keys = Set.new(schema.keys.select{ |k| k.is_a?(Symbol) }.map(&:to_s))
      value.reduce({}) do |accum, (k, v)|
        # convert string keys to symbol keys, if needed
        if k.is_a?(String) && symbol_keys.include?(k)
          k = k.to_sym
        end

        # strip out keys that don't exist in the schema
        if schema.has_key?(k) || schema.has_key?(OptionalHashKey.new(k))
          accum[k] = v
        end

        accum
      end
    end
  end

  GenericHashSchema = Struct.new(:key_subschema, :value_subschema) do
    def schema_walk(value, mapper)
      if not value.is_a?(Hash)
        return RSchema::ErrorDetails.new(value, 'is not a Hash')
      end

      value.reduce({}) do |accum, (k, v)|
        # walk key
        k_walked, error = RSchema.walk(key_subschema, k, mapper)
        break error.extend_key_path('.keys') if error

        # walk value
        v_walked, error = RSchema.walk(value_subschema, v, mapper)
        break error.extend_key_path(k) if error

        accum[k_walked] = v_walked
        accum
      end
    end
  end

  GenericSetSchema = Struct.new(:subschema) do
    def schema_walk(value, mapper)
      return RSchema::ErrorDetails.new(value, 'is not a Set') if not value.is_a?(Set)

      value.reduce(Set.new) do |accum, subvalue|
        subvalue_walked, error = RSchema.walk(subschema, subvalue, mapper)
        break error.extend_key_path('.values') if error

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
        RSchema::ErrorDetails.new(value, 'fails predicate' + (name ? ": #{name}" : ''))
      end
    end
  end

  MaybeSchema = Struct.new(:subschema) do
    def schema_walk(value, mapper)
      if value.nil?
        value
      else
        subvalue_walked, error = RSchema.walk(subschema, value, mapper)
        error || subvalue_walked
      end
    end
  end

  EnumSchema = Struct.new(:value_set, :subschema) do
    def schema_walk(value, mapper)
      value_walked = if subschema
        v, error = RSchema.walk(subschema, value, mapper)
        return error if error
        v
      else
        value
      end

      if value_set.include?(value_walked)
        value_walked
      else
        RSchema::ErrorDetails.new(value_walked, "is not a valid enum member")
      end
    end
  end

  module BooleanSchema
    def self.schema_walk(value, mapper)
      if value.is_a?(TrueClass) || value.is_a?(FalseClass)
        value
      else
        RSchema::ErrorDetails.new(value, 'is not a boolean')
      end
    end
  end

  module AnySchema
    def self.schema_walk(value, mapper)
      value
    end
  end
end

class Class
  def schema_walk(value, mapper)
    if value.is_a?(self)
      value
    else
      RSchema::ErrorDetails.new(value, "is not a #{self.name}, is a #{value.class.name}")
    end
  end
end

class Array
  def schema_walk(value, mapper)
    fixed_size = (size != 1)

    if not value.is_a?(Array)
      RSchema::ErrorDetails.new(value, 'is not an Array')
    elsif fixed_size && value.size != size
      RSchema::ErrorDetails.new(value, "does not have #{size} elements")
    else
      value.each.with_index.map do |subvalue, idx|
        subschema = (fixed_size ? self[idx] : first)
        subvalue_walked, error = RSchema.walk(subschema, subvalue, mapper)
        break error.extend_key_path(idx) if error
        subvalue_walked
      end
    end
  end
end

class Hash
  def schema_walk(value, mapper)
    return RSchema::ErrorDetails.new(value, 'is not a Hash') if not value.is_a?(Hash)

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
      return RSchema::ErrorDetails.new(value, "has extraneous keys: #{extraneous.inspect}")
    end

    # check for required keys that are missing
    missing_requireds = required_keys.reject{ |k| value.has_key?(k) }
    if missing_requireds.size > 0
      return RSchema::ErrorDetails.new(value, "is missing required keys: #{missing_requireds.inspect}")
    end

    # walk the subvalues
    value.reduce({}) do |accum, (k, subvalue)|
      subvalue_walked, error = RSchema.walk(all_subschemas[k], subvalue, mapper)
      break error.extend_key_path(k) if error
      accum[k] = subvalue_walked
      accum
    end
  end
end

