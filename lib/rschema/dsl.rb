module RSchema
  module DSL
    def Type(type)
      Schemas::Type.new(type)
    end
    alias_method :_, :Type

    def Array(*subchemas)
      if subchemas.count == 1
        Schemas::VariableLengthArray.new(subchemas.first)
      else
        Schemas::FixedLengthArray.new(subchemas)
      end
    end

    def Boolean
      Schemas::Boolean.instance
    end

    def Hash(attribute_hash)
      attributes = attribute_hash.map do |dsl_key, value_schema|
        optional = dsl_key.kind_of?(OptionalWrapper)
        key = optional ? dsl_key.key : dsl_key
        Schemas::FixedHash::Attribute.new(key, value_schema, optional)
      end

      Schemas::FixedHash.new(attributes)
    end

    def VariableHash(subschemas)
      #TODO: check that it only has one key/value pair
      key_schema, value_schema = subschemas.first
      Schemas::VariableHash.new(key_schema, value_schema)
    end

    def optional(key)
      OptionalWrapper.new(key)
    end

    def maybe(subschema)
      Schemas::Maybe.new(subschema)
    end

    def enum(*valid_values)
      Schemas::Enum.new(valid_values)
    end

    def either(*subschemas)
      Schemas::Alternation.new(subschemas)
    end

    def predicate(&block)
      Schemas::Predicate.new(block)
    end

    def chain(*subschemas)
      Schemas::Chain.new(subschemas)
    end

    def anything
      Schemas::Anything.instance
    end

    def method_missing(sym, *args, &block)
      type = sym.to_s
      if type.start_with?('_') && args.empty? && block.nil?
        constant = Object.const_get(type[1..-1])
        Type(constant)
      else
        super
      end
    end

    OptionalWrapper = Struct.new(:key)
  end
end
