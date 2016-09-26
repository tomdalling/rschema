module RSchema
  module Schemas

    class FixedHash
      def initialize(attributes)
        @attributes = attributes
      end

      def call(value, options=Options.default)
        results = validated_attributes(value, options)

        if results.values.any?(&:invalid?)
          error_result(results)
        else
          success_result(results)
        end
      end

      def validated_attributes(value_hash, options)
        results = {}

        # TODO: handle missing required attributes
        # TODO: handle extraneous attributes
        @attributes.each do |attr|
          if value_hash.has_key?(attr.key)
            attr_result = attr.value_schema.call(value_hash[attr.key], options)
            results[attr.key] = attr_result
          end
        end

        results
      end

      def error_result(results)
        error = {}

        results.each do |key, attr_result|
          if attr_result.invalid?
            error[key] = attr_result.error
          end
        end

        Result.failure(error)
      end

      def success_result(results)
        Result.success(
          results
            .map{ |key, attr_result| [key, attr_result.value] }
            .to_h
        )
      end

      Attribute = Struct.new(:key, :value_schema, :optional)
    end

  end
end
