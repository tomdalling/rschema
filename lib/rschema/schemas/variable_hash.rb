module RSchema
  module Schemas
    class VariableHash
      def initialize(key_schema, value_schema)
        @key_schema = key_schema
        @value_schema = value_schema
      end

      def call(value, options=Options.default)
        #TODO: this isn't done
        result = {}
        error = {}

        value.each do |key, value|
          key_result = @key_schema.call(key, options)
          if key_result.invalid?
            error[key] = key_result.error
            break
          end

          value_result = @value_schema.call(value, options)
          if value_result.invalid?
            error[key] = value_result.error
            break
          end

          result[key_result.value] = value_result.value
        end

        if error.empty?
          Result.success(result)
        else
          Result.error(error)
        end
      end
    end
  end
end
