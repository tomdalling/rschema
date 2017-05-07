require 'set'

module RSchema
module Coercers
module FixedHash

  # The HTTP standard says that when a form is submitted, all unchecked
  # check boxes will _not_ be sent to the server. That is, they will not
  # be present at all in the params hash.
  #
  # This class coerces these missing values into `false`.
  class DefaultBooleansToFalse
    attr_reader :hash_attributes

    def self.build(schema)
      new(schema)
    end

    def initialize(fixed_hash_schema)
      #TODO: make fixed hash attributes frozen, and eliminate dup
      @hash_attributes = fixed_hash_schema.attributes.map(&:dup)
    end

    def call(value)
      Result.success(default_bools_to_false(value))
    end

    private
      def default_bools_to_false(hash)
        missing_keys = keys_for_bool_defaulting - hash.keys

        if missing_keys.any?
          defaults = missing_keys.map{ |k| [k, false] }.to_h
          hash.merge(defaults)
        else
          hash # no coercion necessary
        end
      end

      def keys_for_bool_defaulting
        @keys_for_bool_defaulting ||= Set.new(
          hash_attributes
            .reject(&:optional)
            .select { |attr| is_bool_schema?(attr.value_schema) }
            .map(&:key)
        )
      end

      def is_bool_schema?(schema)
        # dig through all the coercers
        non_coercer = schema
        while non_coercer.is_a?(Schemas::Coercer)
          non_coercer = non_coercer.subschema
        end

        non_coercer.is_a?(Schemas::Boolean)
      end
  end

end
end
end
