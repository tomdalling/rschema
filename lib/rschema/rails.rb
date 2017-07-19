# frozen_string_literal: true

require 'rschema'
require 'rschema/coercion_wrapper/rack_params'

module RSchema
  module Rails
    #
    # A mixin for ActionController that provides methods for validating params.
    #
    module Controller
      def self.included(klass)
        klass.include(InstanceMethods)
        klass.extend(ClassMethods)
      end

      #
      # Instance methods added to ActionController classes
      #
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
          raise InvalidParams.new(result.error) if result.invalid?
          result.value
        end
      end

      #
      # Class methods added to ActionController classes
      #
      module ClassMethods
        def param_schema(&schema_block)
          schema = RSchema.define_hash(&schema_block)
          RSchema::CoercionWrapper::RACK_PARAMS.wrap(schema)
        end
      end
    end

    #
    # Raised when {validate_params!} fails
    #
    class InvalidParams < StandardError
      attr_reader :error

      def initialize(error)
        @error = error
        super('Parameters do not conform to schema')
      end
    end
  end
end
