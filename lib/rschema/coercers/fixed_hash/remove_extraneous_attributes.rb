module RSchema
module Coercers
module FixedHash

  class RemoveExtraneousAttributes
    attr_reader :hash_attributes

    def self.build(schema)
      new(schema)
    end

    def initialize(fixed_hash_schema)
      #TODO: make fixed hash attributes frozen, and eliminate dup
      @hash_attributes = fixed_hash_schema.attributes.map(&:dup)
    end

    def call(value)
      Result.success(remove_extraneous_elements(value))
    end

    private

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

      def valid_keys
        @valid_keys ||= hash_attributes.map(&:key)
      end
  end

end
end
end
