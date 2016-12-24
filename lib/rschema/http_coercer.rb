module RSchema
  module HTTPCoercer
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
      rescue CoercionFailed
        return Result.failure(Error.new(
          schema: self,
          value: value,
          symbolic_name: :coercion_failure,
        ))
      end

      def with_wrapped_subschemas(wrapper)
        self.class.new(wrapper.wrap(subschema))
      end

      def invalid!
        raise CoercionFailed
      end

      class CoercionFailed < StandardError; end
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
      TRUTHY_STRINGS = ['1', 'true']
      FALSEY_STRINGS = ['0', 'false']

      def coerce(value)
        case
        when value.equal?(true) then true
        when value.equal?(false) then false
        when TRUTHY_STRINGS.include?(value.downcase) then true
        when FALSEY_STRINGS.include?(value.downcase) then false
        else invalid!
        end
      end
    end

    class FixedHashCoercer < Coercer
      def coerce(value)
        symbolize_keys(value)
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
        # these could be cached if we know for sure that the subschema is immutable
        symbol_keys = subschema.attributes
          .map(&:key)
          .select{ |k| k.is_a?(Symbol) }
          .map(&:to_s)

        string_keys = subschema.attributes
          .map(&:key)
          .select{ |k| k.is_a?(String) }

        hash.keys.select do |k|
          k.is_a?(String) && symbol_keys.include?(k) && !string_keys.include?(k)
        end
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
