module RSchema
  #
  # A mixin containing all the standard RSchema DSL methods.
  #
  # If you are making a custom DSL, you can include this mixin to get ONLY the
  # standard RSchema DSL methods, without any of the extra ones that may have
  # been included by third-party gems.
  #
  # @note Do not include your custom DSL methods into this module.
  #   Include them into the {DefaultDSL} class instead.
  #
  # @see RSchema.define
  # @see RSchema.default_dsl
  #
  module DSL
    OptionalWrapper = Struct.new(:key)

    #
    # Creates a {Schemas::Type} schema.
    #
    # The preferred way to create type schemas is using an underscore, like:
    #
    #     _Integer
    #
    # The DSL will turn the above code into:
    #
    #     type(Integer)
    #
    # Underscores will not work for namespaced types (types that include `::`).
    # In that case, it is necessary to use the `type` method:
    #
    #     _MyNamespace::MyType # this will NOT work
    #     type(MyNamespace::MyType) # this will work
    #
    # @param type [Class]
    # @return [Schemas::Type]
    #
    # @example An `Integer` type schema
    #     type(Integer)
    #     # exactly the same as:
    #     _Integer
    #
    def type(type)
      Schemas::Type.new(type)
    end

    #
    # Creates a {Schemas::VariableLengthArray} if given one argument, otherwise
    # creates a {Schemas::FixedLengthArray}
    #
    # @param subschemas [Array<schema>] one or more schema objects representing elements
    #   in the array.
    # @return [Schemas::VariableLengthArray, Schemas::FixedLengthArray]
    #
    # @example A variable-length array schema
    #     array(_Integer)
    #     # matches [1, 2, 3, 4]
    #
    # @example A fixed-length array schema
    #     array(_Integer, _String)
    #     # matches [5, "hello"]
    #
    def array(*subschemas)
      subschemas = subschemas.map{ |ss| inconvenience(ss) }

      if subschemas.count == 1
        Schemas::VariableLengthArray.new(subschemas.first)
      else
        Schemas::FixedLengthArray.new(subschemas)
      end
    end

    #
    # Returns the {Schemas::Boolean} schema
    #
    # @return [Schemas::Boolean]
    #
    # @example The boolean schema
    #     boolean
    #     # matches only `true` and `false`
    #
    def boolean
      Schemas::Boolean.instance
    end

    #
    # Creates a {Schemas::FixedHash} schema
    #
    # @param attribute_hash (see #attributes)
    # @return [Schemas::FixedHash]
    #
    # @example A typical fixed hash schema
    #     fixed_hash(
    #       name: _String,
    #       optional(:age) => _Integer,
    #     )
    #     # matches { name: "Tom" }
    #     # matches { name: "Dane", age: 55 }
    #
    def fixed_hash(attribute_hash)
      Schemas::FixedHash.new(attributes(attribute_hash))
    end
    alias_method :hash, :fixed_hash

    #
    # Creates a {Schemas::Set} schema
    #
    # @param subschema [schema] A schema representing the elements of the set
    # @return [Schemas::Set]
    #
    # @example A set of integers
    #     set(_Integer)
    #     # matches Set[1,2,3]
    #
    def set(subschema)
      Schemas::Set.new(inconvenience(subschema))
    end

    #
    # Wraps a key in an {OptionalWrapper}, for use with the {#fixed_hash} or
    # {#attributes} methods.
    #
    # @param key [Object] Any arbitrary value
    # @return [OptionalWrapper] An {OptionalWrapper} containing the given key.
    #
    # @see OptionalWrapper
    # @see #fixed_hash
    # @see #attributes
    #
    # @example (see #fixed_hash)
    #
    def optional(key)
      OptionalWrapper.new(key)
    end

    #
    # Creates a {Schemas::VariableHash} schema
    #
    # @param subschemas [Hash] A hash with a single key, and a single value.
    #   The key is a schema representing all keys.
    #   The value is a schema representing all values.
    # @return [Schemas::VariableHash]
    #
    # @example A hash of integers to strings
    #     variable_hash(_Integer => _String)
    #     # matches { 5 => "hello", 7 => "world" }
    #
    def variable_hash(subschemas)
      unless subschemas.is_a?(Hash) && subschemas.size == 1
        raise ArgumentError, 'argument must be a Hash of size 1'
      end

      key_schema, value_schema = subschemas.first
      Schemas::VariableHash.new(
        inconvenience(key_schema),
        inconvenience(value_schema),
      )
    end

    #
    # Turns an "attribute hash" into an array of {Schemas::FixedHash::Attribute}.
    # Primarily for use with {Schemas::FixedHash#merge}.
    #
    # @param attribute_hash [Hash<key, schema>] A hash of keys to subschemas.
    #   The values of this parameter must be schema objects.
    #   The keys should be the exact keys expected in the represented `Hash`
    #   (`Strings`, `Symbols`, whatever). Keys can be wrapped with {#optional}
    #   to indicate that the key can be missing in the represented `Hash`.
    # @return [Array<Schemas::FixedHash::Attribute>]
    #
    # @see Schemas::FixedHash#merge
    #
    # @example Merging new attributes into an existing {Schemas::FixedHash} schema
    #     person_schema = fixed_hash(
    #       first_name: _String,
    #       last_name: _String,
    #     )
    #
    #     person_record_schema = person_schema.merge(attributes(
    #       id: _Integer,
    #       optional(:updated_at) => _Time,
    #     ))
    #
    #     # person_record_schema matches:
    #     #  {
    #     #    id: 3,
    #     #    updated_at: Time.now,
    #     #    first_name: "Tom",
    #     #    last_name: "Dalling",
    #     #  }
    #
    def attributes(attribute_hash)
      attribute_hash.map do |dsl_key, value_schema|
        optional = dsl_key.is_a?(OptionalWrapper)
        key = optional ? dsl_key.key : dsl_key
        Schemas::FixedHash::Attribute.new(key, inconvenience(value_schema), optional)
      end
    end

    #
    # Creates a {Schemas::Maybe} schema
    #
    # @param subschema [schema] A schema representing the value, if the value
    #   is not `nil`.
    # @return [Schemas::Maybe]
    #
    # @example A nullable Integer
    #     maybe(_Integer)
    #     # matches 5
    #     # matches nil
    #
    def maybe(subschema)
      Schemas::Maybe.new(inconvenience(subschema))
    end

    #
    # Creates a {Schemas::Enum} schema
    #
    # @param valid_values [Array<Object>] An array of all possible valid values.
    # @param subschema [schema] A schema that represents all enum members.
    #   If this is `nil`, the schema is inferred to be the type of the first
    #   element in `valid_values` (e.g. `enum([:a,:b,:c])` will have `_Symbol`
    #   as the inferred subschema).
    # @return [Schemas::Enum]
    #
    # @example Valid Rock-Paper-Scissors turn values
    #     enum([:rock, :paper, :scissors])
    #     # matches :rock
    #     # matches :paper
    #     # matches :scissors
    #
    def enum(valid_values, subschema=nil)
      subschema = inconvenience(subschema) if subschema
      Schemas::Enum.new(valid_values, subschema || type(valid_values.first.class))
    end

    #
    # Creates a {Schemas::Sum} schema.
    #
    # @param subschemas [Array<schema>] Schemas representing all the possible
    #   valid values.
    # @return [Schemas::Sum]
    #
    # @example A schema that matches both Integers and Strings
    #     either(_String, _Integer)
    #     # matches "hello"
    #     # matches 1337
    #
    def either(*subschemas)
      subschemas = subschemas.map{ |ss| inconvenience(ss) }
      Schemas::Sum.new(subschemas)
    end

    #
    # Creates a {Schemas::Predicate} schema.
    #
    # @param name [String] An optional name for the predicate schema. This
    #   serves no purpose other than to provide useful debugging information,
    #   or perhaps some metadata for the schema.
    # @yield Values being validated are yielded to the given block. The return
    #   value of the block indicates whether the value is valid or not.
    # @yieldparam value [Object] The value being validated
    # @yieldreturn [Boolean] Truthy if the value is valid, otherwise falsey.
    # @return [Schemas::Predicate]
    #
    # @example A predicate that checks if numbers are odd
    #     predicate('odd'){ |x| x.odd? }
    #     # matches 5
    #
    def predicate(name = nil, &block)
      Schemas::Predicate.new(name, &block)
    end

    #
    # Creates a {Schemas::Pipeline} schema.
    #
    # @param subschemas [Array<schema>] The schemas to be pipelined together,
    #   in order.
    # @return [Schemas::Pipeline]
    #
    # @example A schema for positive floats
    #     pipeline(
    #       _Float,
    #       predicate{ |f| f > 0.0 },
    #     )
    #     # matches 6.2
    #
    def pipeline(*subschemas)
      subschemas = subschemas.map{ |ss| inconvenience(ss) }
      Schemas::Pipeline.new(subschemas)
    end

    #
    # Returns the {Schemas::Anything} schema.
    #
    # @return [Schemas::Anything]
    #
    # @example The anything schema
    #   anything
    #   # matches nil
    #   # matches 6.2
    #   # matches { hello: Time.now }
    #
    def anything
      Schemas::Anything.instance
    end

    def convenience(schema)
      Schemas::Convenience.wrap(schema)
    end

    def inconvenience(schema)
      Schemas::Convenience.unwrap(schema)
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

    # @!visibility private
    def respond_to?(sym, include_all=false)
      # check if method starts with an underscore followed by a capital
      super || !!sym.to_s.match(/\A_[A-Z]/)
    end
  end
end
