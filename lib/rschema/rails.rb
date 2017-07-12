require 'rschema'
require 'rschema/coercion_wrapper/rack_params'

module RSchema
module Rails

  module Controller
    def self.included(klass)
      klass.include(InstanceMethods)
      klass.extend(ClassMethods)
    end

    module InstanceMethods
      def param_schema(&schema_block)
        self.class.param_schema(&schema_block)
      end

      def validate_params(schema = nil, &schema_block)
        schema ||= param_schema(&schema_block)
        schema.validate(request.parameters.to_hash)
      end

      def validate_params!(*args, &block)
        result = validate_params(*args, &block)
        if result.valid?
          result.value
        else
          raise InvalidParams.new(result.error)
        end
      end
    end

    module ClassMethods
      def param_schema(&schema_block)
        schema = RSchema.define_hash(&schema_block)
        RSchema::CoercionWrapper::RACK_PARAMS.wrap(schema)
      end
    end
  end

  class InvalidParams < StandardError
    attr_reader :error

    def initialize(error)
      @error = error
      super("Parameters do not conform to schema")
    end
  end


end
end
