module RSchema
  module HTTPCoercer
    class CanNotBeWrappedError < StandardError; end

    def self.wrap(schema)
      coercer_klass = begin
        case schema
        when Schemas::Type then TYPE_COERCERS[schema.type]
        when Schemas::Boolean then BoolCoercer
        when Schemas::FixedHash then FixedHashCoercer
        end
      end

      wrapped_schema = schema.with_wrapped_subschemas(self)
      coercer_klass ? coercer_klass.new(wrapped_schema) : wrapped_schema
    end

    class Coercer
      attr_reader :subschema

      def initialize(subschema)
        @subschema = subschema
      end

      def call(value, options=RSchema::Options.default)
        @subschema.call(coerce(value), options)
      rescue CoercionFailedError
        return Result.failure(Error.new(
          schema: self,
          value: value,
          symbolic_name: :coercion_failure,
        ))
      end

      def with_wrapped_subschemas(wrapper)
        # Double wrapping is potentially a problem. Coercers expect their
        # subschemas to be a particular type. If their subschema gets wrapped
        # again, the type changes, so if the coercer tries to use its subschema
        # during coercion, it will crash.
        #
        # For this reason, coercers must not rely upon the type of their
        # subschemas within `#call`. Coercer schemas should store any required
        # info from their subschemas within `#initialize`.

        self.class.new(wrapper.wrap(subschema))
      end

      def invalid!
        raise CoercionFailedError
      end

      class CoercionFailedError < StandardError; end
    end

    class TimeCoercer < Coercer
      def coerce(value)
        case value
        when Time then value
        when String then Time.iso8601(value) rescue invalid!
        else invalid!
        end
      end
    end

    class DateCoercer < Coercer
      def coerce(value)
        case value
        when Date then value
        when String then Date.iso8601(value) rescue invalid!
        else invalid!
        end
      end
    end

    class SymbolCoercer < Coercer
      def coerce(value)
        case value
        when Symbol then value
        when String then value.to_sym
        else invalid!
        end
      end
    end

    class IntegerCoercer < Coercer
      def coerce(value)
        Integer(value)
      rescue ArgumentError
        invalid!
      end
    end

    class FloatCoercer < Coercer
      def coerce(value)
        Float(value)
      rescue ArgumentError
        invalid!
      end
    end

    class BoolCoercer < Coercer
      TRUTHY_STRINGS = ['on', '1', 'true']
      FALSEY_STRINGS = ['off', '0', 'false']

      def coerce(value)
        case value
        when true, false then value
        when nil then false
        when String
          case
          when TRUTHY_STRINGS.include?(value.downcase) then true
          when FALSEY_STRINGS.include?(value.downcase) then false
          else invalid!
          end
        else invalid!
        end
      end
    end

    class FixedHashCoercer < Coercer
      attr_reader :hash_attributes

      def initialize(fixed_hash_schema, attributes = nil)
        super(fixed_hash_schema)

        @hash_attributes = attributes || fixed_hash_schema.attributes.map(&:dup)
      end

      def coerce(value)
        [value]
          .map(&method(:symbolize_keys))
          .map(&method(:remove_extraneous_elements))
          .map(&method(:default_bools_to_false))
          .last
      end

      def symbolize_keys(hash)
        keys = keys_to_symbolize(hash)
        if keys.any?
          hash.dup.tap do |new_hash|
            keys.each { |k| new_hash[k.to_sym] = new_hash.delete(k) }
          end
        else
          hash
        end
      end

      def keys_to_symbolize(hash)
        # some of this could be memoized
        symbol_keys = hash_attributes
          .map(&:key)
          .select{ |k| k.is_a?(Symbol) }
          .map(&:to_s)

        string_keys = hash_attributes
          .map(&:key)
          .select{ |k| k.is_a?(String) }

        hash.keys.select do |k|
          symbol_keys.include?(k) && !string_keys.include?(k)
        end
      end

      def remove_extraneous_elements(hash)
        valid_keys = hash_attributes.map(&:key)
        keys_to_remove = hash.keys - valid_keys

        if keys_to_remove.any?
          hash.dup.tap do |stripped_hash|
            keys_to_remove.each { |k| stripped_hash.delete(k) }
          end
        else
          hash
        end
      end

      def default_bools_to_false(hash)
        # The HTTP standard says that when a form is submitted, all unchecked
        # check boxes will _not_ be sent to the server. That is, they will not
        # be present at all in the params hash.
        #
        # This method coerces these missing values into `false`.

        missing_keys = keys_for_bool_defaulting
          .reject { |key| hash.has_key?(key) }

        if missing_keys.any?
          defaults = missing_keys.map{ |k| [k, false] }.to_h
          hash.merge(defaults)
        else
          hash # no coercion necessary
        end
      end

      def with_wrapped_subschemas(wrapper)
        self.class.new(wrapper.wrap(subschema), hash_attributes)
      end

      private

        def keys_for_bool_defaulting
          # this could be memoized
          hash_attributes
            .reject(&:optional)
            .select { |attr| attr.value_schema.is_a?(BoolCoercer) }
            .map(&:key)
        end
    end

    TYPE_COERCERS = {
      Symbol => SymbolCoercer,
      Integer => IntegerCoercer,
      Float => FloatCoercer,
      Time => TimeCoercer,
      Date => DateCoercer,
    }
  end
end
