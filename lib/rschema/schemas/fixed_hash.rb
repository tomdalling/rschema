module RSchema
  module Schemas

    class FixedHash
      Attribute = Struct.new(:key, :value_schema, :optional)

      attr_reader :attributes

      def initialize(attributes)
        @attributes = attributes
      end

      def call(value, options=Options.default)
        return not_a_hash_result(value) unless value.is_a?(Hash)
        return missing_attrs_result(value) if missing_keys(value).any?
        return extraneous_attrs_result(value) if extraneous_keys(value).any?

        subresults = attr_subresults(value, options)
        if subresults.values.any?(&:invalid?)
          Result.failure(failure_error(subresults))
        else
          Result.success(success_value(subresults))
        end
      end

      private

      def missing_keys(value)
        attributes
          .reject(&:optional)
          .map(&:key)
          .reject{ |k| value.has_key?(k) }
      end

      def missing_attrs_result(value)
        Result.failure(Error.new(
          schema: self,
          value: value,
          symbolic_name: 'rschema/fixed_hash/missing_attributes',
          vars: missing_keys(value),
        ))
      end

      def extraneous_keys(value)
        allowed_keys = attributes.map(&:key)
        value.keys.reject{ |k| allowed_keys.include?(k) }
      end

      def extraneous_attrs_result(value)
        Result.failure(Error.new(
          schema: self,
          value: value,
          symbolic_name: 'rschema/fixed_hash/extraneous_attributes',
          vars: extraneous_keys(value),
        ))
      end

      def attr_subresults(value, options)
        subresults_by_key = {}

        @attributes.map do |attr|
          if value.has_key?(attr.key)
            subresult = attr.value_schema.call(value[attr.key], options)
            subresults_by_key[attr.key] = subresult
            break if subresult.invalid? && options.fail_fast?
          end
        end

        subresults_by_key
      end

      def failure_error(results)
        error = {}

        results.each do |key, attr_result|
          if attr_result.invalid?
            error[key] = attr_result.error
          end
        end

        error
      end

      def success_value(subresults)
        subresults
          .map{ |key, attr_result| [key, attr_result.value] }
          .to_h
      end

      def not_a_hash_result(value)
        Result.failure(
          Error.new(
            schema: self,
            value: value,
            symbolic_name: 'rschema/fixed_hash/not_a_hash',
          )
        )
      end
    end

  end
end
