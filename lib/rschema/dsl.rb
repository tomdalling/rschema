# frozen_string_literal: true

module RSchema
  #
  # A mixin containing all the standard RSchema DSL methods.
  #
  # This mixin contains only the standard RSchema DSL methods, without any of
  # the extra ones that may have been included by third-party gems/code.
  #
  # @note Do not include your custom DSL methods into this module.
  #   Include them into the {DefaultDSL} class instead.
  #
  # @see RSchema.define
  # @see RSchema.default_dsl
  #
  module DSL
    # A wrapper class used only by {DSL} to represent optional attributes.
    #
    # @see #attributes
    # @see #fixed_hash
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
    # In that case, it is necessary to use the `type` method.
    #
    # @param type [Class]
    # @return [Schemas::Type]
    #
    # @example (see Schemas::Type)
    #
    def type(type)
      Schemas::Type.new(type)
    end

    #
    # Creates a {Schemas::VariableLengthArray} if given one argument, otherwise
    # creates a {Schemas::FixedLengthArray}
    #
    # @param subschemas [Array<schema>] one or more schema objects representing
    #   elements in the array.
    # @return [Schemas::VariableLengthArray, Schemas::FixedLengthArray]
    #
    # @example (see Schemas::VariableLengthArray)
    # @example (see Schemas::FixedLengthArray)
    #
    def array(*subschemas)
      subschemas = subschemas.map { |ss| inconvenience(ss) }

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
    # @example (see Schemas::Boolean)
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
    # @example (see Schemas::FixedHash)
    #
    # @see RSchema.define_hash
    # @see #variable_hash
    #
    def fixed_hash(attribute_hash)
      Schemas::FixedHash.new(attributes(attribute_hash))
    end
    alias hash fixed_hash

    #
    # Creates a {Schemas::Set} schema
    #
    # @param subschema [schema] A schema representing the elements of the set
    # @return [Schemas::Set]
    #
    # @example (see Schemas::Set)
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
    # @example (see Schemas::VariableHash)
    #
    # @see #fixed_hash
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
    # Turns an "attribute hash" into an array of
    # {Schemas::FixedHash::Attribute}. Primarily for use with
    # {Schemas::FixedHash#merge}.
    #
    # @param attribute_hash [Hash<key, schema>] A hash of keys to subschemas.
    #   The values of this hash must be schema objects.
    #   The keys should be the exact keys expected in the represented `Hash`
    #   (`Strings`, `Symbols`, whatever). Keys can be wrapped with {#optional}
    #   to indicate that they can be missing from the represented `Hash`.
    # @return [Array<Schemas::FixedHash::Attribute>]
    #
    # @see Schemas::FixedHash#merge
    #
    # @example (see Schemas::FixedHash#merge)
    #
    def attributes(attribute_hash)
      attribute_hash.map do |dsl_key, value_schema|
        optional = dsl_key.is_a?(OptionalWrapper)
        key = optional ? dsl_key.key : dsl_key
        Schemas::FixedHash::Attribute.new(
          key, inconvenience(value_schema), optional,
        )
      end
    end

    #
    # Creates a {Schemas::Maybe} schema
    #
    # @param subschema [schema] A schema representing the value, if the value
    #   is not `nil`.
    # @return [Schemas::Maybe]
    #
    # @example (see Schemas::Maybe)
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
    # @example (see Schemas::Enum)
    #
    def enum(valid_values, subschema = nil)
      subschema = inconvenience(subschema) if subschema
      Schemas::Enum.new(
        valid_values, subschema || type(valid_values.first.class),
      )
    end

    #
    # Creates a {Schemas::Sum} schema.
    #
    # @param subschemas [Array<schema>] Schemas representing all the possible
    #   valid values.
    # @return [Schemas::Sum]
    #
    # @example (see Schemas::Sum)
    #
    def either(*subschemas)
      subschemas = subschemas.map { |ss| inconvenience(ss) }
      Schemas::Sum.new(subschemas)
    end

    #
    # Creates a {Schemas::Predicate} schema.
    #
    # @param name [String] An optional name for the predicate schema. This
    #   serves no purpose other than to provide useful debugging information,
    #   or perhaps some metadata.
    # @yield Values being validated are yielded to the given block. The return
    #   value of the block indicates whether the value is valid or not.
    # @yieldparam value [Object] The value being validated
    # @yieldreturn [Boolean] Truthy if the value is valid, otherwise falsey.
    # @return [Schemas::Predicate]
    #
    # @example (see Schemas::Predicate)
    #
    # @see RSchema.define_predicate
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
    # @example (see Schemas::Pipeline)
    #
    def pipeline(*subschemas)
      subschemas = subschemas.map { |ss| inconvenience(ss) }
      Schemas::Pipeline.new(subschemas)
    end

    #
    # Returns the {Schemas::Anything} schema.
    #
    # @return [Schemas::Anything]
    #
    # @example (see Schemas::Anything)
    #
    def anything
      Schemas::Anything.instance
    end

    #
    # Wraps a schema in a {Schemas::Convenience}
    #
    # It is not normally necessary to do this wrapping manually. Methods like
    # {RSchema.define}, {RSchema.define_predicate} and {RSchema.define_hash}
    # already return schema objects wrapped in {Schemas::Convenience}.
    #
    # @param schema [schema] The schema to wrap
    # @return [Schemas::Convenience]
    #
    # @example Manually wrapping a schema with `convenience`
    #     # Unlike `RSchema.define`, the `RSchema.dsl_eval` method does not
    #     # wrap the return value with RSchema::Schemas::Convenience, so the
    #     # returned schema is missing convenience methods like `valid?`
    #     schema = RSchema.dsl_eval { _Integer }
    #     schema.valid?(5) #=> NoMethodError: undefined method `valid?'
    #
    #     # After manually wrapping the schema, the convenience methods are
    #     # available
    #     schema = RSchema.dsl_eval { convenience(_Integer) }
    #     schema.valid?(5) #=> true
    #
    def convenience(schema)
      Schemas::Convenience.wrap(schema)
    end

    #
    # Removes any {Schemas::Convenience} wrappers from a schema.
    #
    # This method is only really useful when defining your own custom DSL
    # methods.
    #
    # When creating a composite schema that contains other subschemas, it is
    # unneccessary to have the subschemas wrapped in {Schemas::Convenience}.
    # Using wrapped subschemas should not cause any errors, but unwrapped
    # subschemas will have slightly better performance. So, when your custom
    # DSL method is creating a composite schema, use {#inconvenience} to unwrap
    # all the subschemas.
    #
    # @return [schema] The underlying schema object, once all convenience
    #   wrappers have been removed.
    #
    # @example Unwrapping subschemas in a custom DSL method
    #     module MyCustomDSL
    #       def pair(subschema)
    #         unwrapped = inconvenience(subschema)
    #         RSchema::Schemas::FixedLengthArray.new([unwrapped, unwrapped])
    #       end
    #     end
    #
    #     RSchema::DefaultDSL.include(MyCustomDSL)
    #
    #     schema = RSchema.define{ pair(_Integer) }
    #     schema.valid?([4, 6]) #=> true
    #
    def inconvenience(schema)
      Schemas::Convenience.unwrap(schema)
    end

    #
    # Convenient way to create {Schemas::Type} schemas
    #
    # See {#type} for details.
    #
    # @see #type
    #
    def method_missing(sym, *args, &block)
      type = sym.to_s
      if type.start_with?('_') && args.empty? && block.nil?
        constant = Object.const_get(type[1..])
        type(constant)
      else
        super
      end
    end

    # @!visibility private
    def respond_to_missing?(sym, include_all = false)
      # check if method starts with an underscore followed by a capital
      super || sym.to_s.match(/\A_[A-Z]/)
    end
  end
end
