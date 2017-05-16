module RSchema
  module DSL
    OptionalWrapper = Struct.new(:key)

    def type(type)
      Schemas::Type.new(type)
    end

    def array(*subchemas)
      if subchemas.count == 1
        Schemas::VariableLengthArray.new(subchemas.first)
      else
        Schemas::FixedLengthArray.new(subchemas)
      end
    end

    def boolean
      Schemas::Boolean.instance
    end

    def fixed_hash(attribute_hash)
      Schemas::FixedHash.new(attributes(attribute_hash))
    end
    def hash(*args); fixed_hash(*args); end

    def set(subschema)
      Schemas::Set.new(subschema)
    end

    def optional(key)
      OptionalWrapper.new(key)
    end

    def variable_hash(subschemas)
      unless subschemas.is_a?(Hash) && subschemas.size == 1
        raise ArgumentError, 'argument must be a Hash of size 1'
      end

      key_schema, value_schema = subschemas.first
      Schemas::VariableHash.new(key_schema, value_schema)
    end

    def attributes(attribute_hash)
      attribute_hash.map do |dsl_key, value_schema|
        optional = dsl_key.is_a?(OptionalWrapper)
        key = optional ? dsl_key.key : dsl_key
        Schemas::FixedHash::Attribute.new(key, value_schema, optional)
      end
    end

    def maybe(subschema)
      Schemas::Maybe.new(subschema)
    end

    def enum(valid_values, subschema=nil)
      Schemas::Enum.new(valid_values, subschema || type(valid_values.first.class))
    end

    def either(*subschemas)
      Schemas::Sum.new(subschemas)
    end

    def predicate(name = nil, &block)
      Schemas::Predicate.new(block, name)
    end

    def pipeline(*subschemas)
      Schemas::Pipeline.new(subschemas)
    end

    def anything
      Schemas::Anything.instance
    end

    def method_missing(sym, *args, &block)
      type = sym.to_s
      if type.start_with?('_') && args.empty? && block.nil?
        constant = Object.const_get(type[1..-1])
        type(constant)
      else
        super
      end
    end

    def respond_to?(sym, include_all=false)
      # check if method starts with an underscore followed by a capital
      super || !!sym.to_s.match(/\A_[A-Z]/)
    end
  end
end
