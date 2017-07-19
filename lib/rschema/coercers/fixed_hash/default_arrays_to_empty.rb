# frozen_string_literal: true

require 'set'

module RSchema
  module Coercers
    module FixedHash
      # The HTTP standard says that when a form is submitted, all unchecked
      # check boxes will _not_ be sent to the server. That is, they will not
      # be present at all in the params hash.
      #
      # This class coerces these missing values into an empty array, where an
      # array is expected.
      class DefaultArraysToEmpty
        attr_reader :hash_attributes

        def self.build(schema)
          new(schema)
        end

        def initialize(fixed_hash_schema)
          # TODO: make fixed hash attributes frozen, and eliminate dup
          @hash_attributes = fixed_hash_schema.attributes.map(&:dup)
        end

        def call(value)
          Result.success(default_arrays_to_empty(value))
        end

        def will_affect?(value)
          keys_to_default(value).any?
        end

        private

        def default_arrays_to_empty(hash)
          missing_keys = keys_to_default(hash)

          if missing_keys.any?
            defaults = missing_keys.map { |k| [k, []] }.to_h
            hash.merge(defaults)
          else
            hash # no coercion necessary
          end
        end

        def keys_to_default(value)
          if value.is_a?(Hash)
            keys_for_array_defaulting - value.keys
          else
            []
          end
        end

        def keys_for_array_defaulting
          @keys_for_array_defaulting ||= Set.new(
            hash_attributes
              .reject(&:optional)
              .select { |attr| array_schema?(attr.value_schema) }
              .map(&:key),
          )
        end

        def array_schema?(schema)
          # dig through all the coercers
          non_coercer = schema
          while non_coercer.is_a?(Schemas::Coercer)
            non_coercer = non_coercer.subschema
          end

          non_coercer.is_a?(Schemas::VariableLengthArray)
        end
      end
    end
  end
end
