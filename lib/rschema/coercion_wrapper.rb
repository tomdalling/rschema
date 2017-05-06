module RSchema
  class CoercionWrapper
    def initialize(&initializer)
      @coercers_by_schemas = {}
      @coercers_by_type = {}
      instance_eval(&initializer) if initializer
    end

    def coerce_schemas(coercers_by_schemas)
      @coercers_by_schemas.merge!(coercers_by_schemas)
    end

    def coerce_types(coercers_by_type)
      @coercers_by_type.merge!(coercers_by_type)
    end

    def wrap(schema)
      wrapped_schema = schema.with_wrapped_subschemas(self)
      coercer_class = coercer_class_for_schema(schema)

      if coercer_class
        coercer = coercer_class.new(wrapped_schema)
        Schemas::Coercer.new(coercer, wrapped_schema)
      else
        wrapped_schema
      end
    end

    private

      def coercer_class_for_schema(schema)
        @coercers_by_schemas.fetch(schema.class) do
          if schema.is_a?(Schemas::Type)
            @coercers_by_type.fetch(schema.type, nil)
          end
        end
      end

  end
end
