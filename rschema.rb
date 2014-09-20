require 'set'

module RSchema
  InvalidSchemaError = Class.new(StandardError)
  ValidationFailedError = Class.new(StandardError)
  WALKERS = []

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
    result = walk(schema, value, CoersionMapper)
    result.is_a?(RSchema::ErrorDetails) ? nil : result
  end

  def self.coerce!(schema, value)
    result = walk(schema, value, CoersionMapper)
    raise(ValidationFailedError, result) if result.is_a?(RSchema::ErrorDetails)
    result
  end

  def self.walk(schema, value, mapper = nil)
    walker = self.walker_for(schema)
    raise(InvalidSchemaError, schema) unless walker

    value = mapper.prewalk(schema, value) if mapper
    value = walker.walk(schema, value, mapper)
    value = mapper.postwalk(schema, value) if mapper
    value
  end

  def self.register_walker(klass, walker)
    WALKERS.insert(0, [klass, walker])
  end

  def self.walker_for(schema)
    WALKERS.each do |(klass, walker)|
      if schema.is_a?(klass)
        return walker
      end
    end
    nil
  end
end

module RSchema
  OptionalHashKey = Struct.new(:key)

  class DSL
    def self._?(key)
      OptionalHashKey.new(key)
    end
  end
end

module RSchema
  module CoersionMapper
    def self.prewalk(schema, value)
      if schema == Integer && value.is_a?(String)
        value.to_i #TODO: this conversion needs to be more robust
      elsif schema == Float && value.is_a?(String)
        value.to_f #TODO: this conversion needs to be more robust
      elsif schema == Symbol && value.is_a?(String)
        value.to_sym #TODO: this conversion needs to be more robust
      elsif schema == String && value.is_a?(Symbol)
        value.to_s
      elsif schema == Array && value.is_a?(Set)
        value.to_a
      elsif schema == Set && value.is_a?(Array)
        Set.new(value)
      else
        value
      end
    end

    def self.postwalk(schema, value)
      value
    end
  end
end

module RSchema
  module ClassWalker
    def self.walk(schema, value, mapper)
      if value.is_a?(schema)
        value
      else
        RSchema::ErrorDetails.new("is not a #{schema}")
      end
    end
  end
end

module RSchema
  module ArrayWalker
    def self.walk(schema, value, mapper)
      fixed_size = (schema.size != 1)

      if not value.is_a?(Array)
        RSchema::ErrorDetails.new("is not an Array")
      elsif fixed_size && value.size != schema.size
        RSchema::ErrorDetails.new("does not have #{schema.size} elements")
      else
        value.each.with_index.map do |subvalue, idx|
          subschema = (fixed_size ? schema[idx] : schema.first )
          subvalue_walked = RSchema.walk(subschema, subvalue, mapper)
          if subvalue_walked.is_a?(RSchema::ErrorDetails)
            break RSchema::ErrorDetails.new({ idx => subvalue_walked.details })
          end
          subvalue_walked
        end
      end
    end
  end
end

module RSchema
  module HashWalker
    InvalidSchemaHashKeyError = Class.new(StandardError)

    def self.walk(schema, value, mapper)
      # must be a hash
      if not value.is_a?(Hash)
        return RSchema::ErrorDetails.new("is not a Hash")
      end

      # extract details from the schema
      required_keys = Set.new
      all_subschemas = {}
      schema.each do |(k, subschema)|
        if k.is_a?(OptionalHashKey)
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
end

RSchema.register_walker(Class, RSchema::ClassWalker)
RSchema.register_walker(Array, RSchema::ArrayWalker)
RSchema.register_walker(Hash, RSchema::HashWalker)

