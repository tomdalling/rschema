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
  GenericHash = Struct.new(:key_subschema, :value_subschema)
  GenericSet = Struct.new(:subschema)
  Predicate = Struct.new(:name, :block)
  Maybe = Struct.new(:subschema)
  Enum = Struct.new(:value_set, :subschema)

  module DSL
    def self._?(key)
      OptionalHashKey.new(key)
    end

    def self.hash_of(subschemas_hash)
      raise InvalidSchemaError unless subschemas_hash.size == 1
      GenericHash.new(subschemas_hash.keys.first, subschemas_hash.values.first)
    end

    def self.set_of(subschema)
      GenericSet.new(subschema)
    end

    def self.predicate(name = nil, &block)
      raise InvalidSchemaError unless block
      Predicate.new(name, block)
    end

    def self.maybe(subschema)
      Maybe.new(subschema)
    end

    def self.enum(possible_values, subschema = nil)
      Enum.new(Set.new(possible_values), subschema)
    end
  end
end

module RSchema
  module CoersionMapper
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
      elsif (schema == Set || schema.is_a?(GenericSet)) && value.is_a?(Array)
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

module RSchema
  module GenericHashWalker
    def self.walk(generic_hash_schema, value, mapper)
      if not value.is_a?(Hash)
        return RSchema::ErrorDetails.new('is not a Hash')
      end

      value.reduce({}) do |accum, (k, v)|
        # walk key
        k_walked = RSchema.walk(generic_hash_schema.key_subschema, k, mapper)
        if k_walked.is_a?(RSchema::ErrorDetails)
          break RSchema::ErrorDetails.new({'has invalid key, where'  => k_walked.details})
        end

        # walk value
        v_walked = RSchema.walk(generic_hash_schema.value_subschema, v, mapper)
        if v_walked.is_a?(RSchema::ErrorDetails)
          break RSchema::ErrorDetails.new({k => v_walked.details})
        end

        accum[k_walked] = v_walked
        accum
      end
    end
  end
end

module RSchema
  module GenericSetWalker
    def self.walk(generic_set_schema, value, mapper)
      if not value.is_a?(Set)
        return RSchema::ErrorDetails.new('is not a Set')
      end

      value.reduce(Set.new) do |accum, subvalue|
        subvalue_walked = RSchema.walk(generic_set_schema.subschema, subvalue, mapper)

        if subvalue_walked.is_a?(RSchema::ErrorDetails)
          break RSchema::ErrorDetails.new(Set.new([subvalue_walked.details]))
        end

        accum << subvalue_walked
        accum
      end
    end
  end
end

module RSchema
  module PredicateWalker
    def self.walk(pred_schema, value, mapper)
      if pred_schema.block.call(value)
        value
      else
        n = pred_schema.name
        RSchema::ErrorDetails.new("fails predicate" + (n ? ": #{n}" : ''))
      end
    end
  end
end

module RSchema
  module MaybeWalker
    def self.walk(maybe_schema, value, mapper)
      if value.nil?
        value
      else
        RSchema.walk(maybe_schema.subschema, value, mapper)
      end
    end
  end
end

module RSchema
  module EnumWalker
    def self.walk(enum_schema, value, mapper)
      value_walked = if enum_schema.subschema
        RSchema.walk(enum_schema.subschema, value, mapper)
      else
        value
      end

      if enum_schema.value_set.include?(value_walked)
        value_walked
      else
        RSchema::ErrorDetails.new('is not a valid enum member')
      end
    end
  end
end

RSchema.register_walker(Class, RSchema::ClassWalker)
RSchema.register_walker(Array, RSchema::ArrayWalker)
RSchema.register_walker(Hash, RSchema::HashWalker)
RSchema.register_walker(RSchema::GenericHash, RSchema::GenericHashWalker)
RSchema.register_walker(RSchema::GenericSet, RSchema::GenericSetWalker)
RSchema.register_walker(RSchema::Predicate, RSchema::PredicateWalker)
RSchema.register_walker(RSchema::Maybe, RSchema::MaybeWalker)
RSchema.register_walker(RSchema::Enum, RSchema::EnumWalker)

