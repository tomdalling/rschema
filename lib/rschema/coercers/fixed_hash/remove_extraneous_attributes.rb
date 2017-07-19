# frozen_string_literal: true

module RSchema
  module Coercers
    module FixedHash
      #
      # Removes elements from `Hash` values that are not defined in the given
      # `FixedHash` schema.
      #
      class RemoveExtraneousAttributes
        attr_reader :hash_attributes

        def self.build(schema)
          new(schema)
        end

        def initialize(fixed_hash_schema)
          # TODO: make fixed hash attributes frozen, and eliminate dup
          @hash_attributes = fixed_hash_schema.attributes.map(&:dup)
        end

        def call(value)
          Result.success(remove_extraneous_elements(value))
        end

        def will_affect?(value)
          keys_to_remove(value).any?
        end

        private

        def remove_extraneous_elements(hash)
          extra_keys = keys_to_remove(hash)

          if extra_keys.any?
            hash.dup.tap do |stripped_hash|
              extra_keys.each { |k| stripped_hash.delete(k) }
            end
          else
            hash
          end
        end

        def keys_to_remove(value)
          if value.is_a?(Hash)
            value.keys - valid_keys
          else
            []
          end
        end

        def valid_keys
          @valid_keys ||= hash_attributes.map(&:key)
        end
      end
    end
  end
end
