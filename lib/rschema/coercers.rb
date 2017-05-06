module RSchema
module Coercers

  class Time
    def initialize(schema)
    end

    def call(value)
      case value
      when ::Time
        Result.success(value)
      when ::String
        time = ::Time.parse(value) rescue nil
        time ? Result.success(time) : Result.failure
      else
        Result.failure
      end
    end
  end

  class Date
    def initialize(schema)
    end

    def call(value)
      case value
      when ::Date
        Result.success(value)
      when ::String
        date = ::Date.parse(value) rescue nil
        date ? Result.success(date) : Result.failure
      else
        Result.failure
      end
    end
  end

  class Symbol
    def initialize(schema)
    end

    def call(value)
      case value
      when ::Symbol then Result.success(value)
      when ::String then Result.success(value.to_sym)
      else Result.failure
      end
    end
  end

  class Integer
    def initialize(schema)
    end

    def call(value)
      int = Integer(value) rescue nil
      int ? Result.success(int) : Result.failure
    end
  end

  class Float
    def initialize(schema)
    end

    def call(value)
      flt = Float(value) rescue nil
      flt ? Result.success(flt) : Result.failure
    end
  end

  class Boolean
    TRUTHY_STRINGS = ['on', '1', 'true', 'yes']
    FALSEY_STRINGS = ['off', '0', 'false', 'no']

    def initialize(schema)
    end

    def call(value)
      case value
      when true, false then Result.success(value)
      when nil then Result.success(false)
      when String
        case
        when TRUTHY_STRINGS.include?(value.downcase) then Result.success(true)
        when FALSEY_STRINGS.include?(value.downcase) then Result.success(false)
        else Result.failure
        end
      else Result.failure
      end
    end
  end

  module HTTP
    class ParamHash
      attr_reader :hash_attributes

      def initialize(fixed_hash_schema)
        #TODO: make fixed hash attributes frozen, and eliminate dup
        @hash_attributes = fixed_hash_schema.attributes.map(&:dup)
      end

      def call(value)
        Result.success(
          default_bools_to_false(
            remove_extraneous_elements(
              symbolize_keys(value)
            )
          )
        )
      end

      private

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
          (hash.keys - string_keys)
            .select { |k| symbol_keys_as_strings.include?(k) }
        end

        def symbol_keys_as_strings
          @symbol_keys_as_strings ||= hash_attributes
            .map(&:key)
            .select{ |k| k.is_a?(::Symbol) }
            .map(&:to_s)
        end

        def string_keys
          @string_keys ||= hash_attributes
            .map(&:key)
            .select{ |k| k.is_a?(::String) }
        end

        def valid_keys
          @valid_keys ||= hash_attributes.map(&:key)
        end

        def remove_extraneous_elements(hash)
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

        def keys_for_bool_defaulting
          @keys_for_bool_defaulting ||= hash_attributes
            .reject(&:optional)
            .select { |attr| is_bool_schema?(attr.value_schema) }
            .map(&:key)
        end

        def is_bool_schema?(schema)
          schema.is_a?(Schemas::Boolean) ||
          (schema.is_a?(Schemas::Coercer) && schema.coercer.is_a?(Coercers::Boolean))
        end
    end
  end

end
end
