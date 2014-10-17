module RSchema
  module RailsInterop
    ParamSchemaValidationError = Class.new(StandardError)

    module ControllerMethods
      def params_for_schema!(schema_arg = nil, &block)
        schema = schema_arg || RSchema.schema(&block)
        value = self.params
        coerced, error = RSchema.coerce(schema, value)
        if error
          raise ParamSchemaValidationError.new(schema: schema, params: value, error: e)    
        else
          coerced
        end
      end
    end

  end
end
