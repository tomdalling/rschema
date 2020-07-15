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
        DEFAULT_OPTIONS = {
          coercion_wrapper: RSchema::CoercionWrapper::RACK_PARAMS
        }.freeze

        def param_schema(&schema_block)
          schema = RSchema.define_hash(&schema_block)
          coercer = rschema_options.fetch(:coercion_wrapper)
          coercer ? coercer.wrap(schema) : schema
        end

        def rschema_options(options = nil)
          if options.nil?
            __rschema_get_options
          else
            @__rschema_options ||= {}
            @__rschema_options.merge!(options)
          end
        end

        def __rschema_get_options
          ancestors.reverse.reduce(DEFAULT_OPTIONS) do |options, klass|
            if klass.instance_variable_defined?(:@__rschema_options)
              options.merge(klass.instance_variable_get(:@__rschema_options))
            else
              options
            end
          end
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
