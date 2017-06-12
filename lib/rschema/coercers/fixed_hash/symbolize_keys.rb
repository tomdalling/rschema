require 'set'

module RSchema
module Coercers
module FixedHash

  class SymbolizeKeys
    attr_reader :hash_attributes

    def self.build(schema)
      new(schema)
    end

    def initialize(fixed_hash_schema)
      #TODO: make fixed hash attributes frozen, and eliminate dup
      @hash_attributes = fixed_hash_schema.attributes.map(&:dup)
    end

    def call(value)
      Result.success(symbolize_keys(value))
    end

    def will_affect?(value)
      keys_to_symbolize(hash).any?
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

      def keys_to_symbolize(value)
        if value.is_a?(Hash)
          non_string_keys = Set.new(value.keys) - string_keys
          non_string_keys.intersection(symbol_keys_as_strings)
        else
          []
        end
      end

      def symbol_keys_as_strings
        @symbol_keys_as_strings ||= Set.new(
          all_keys
            .select{ |k| k.is_a?(::Symbol) }
            .map(&:to_s)
        )
      end

      def string_keys
        @string_keys ||= Set.new(
          all_keys.select { |k| k.is_a?(::String) }
        )
      end

      def all_keys
        @all_keys ||= hash_attributes.map(&:key)
      end
  end

end
end
end
