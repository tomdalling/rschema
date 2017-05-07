module RSchema
  class CoercionWrapper
    def initialize(&initializer)
      @builders_by_schema = {}
      @builders_by_type = {}
      instance_eval(&initializer) if initializer
    end

    def coerce(schema_type, with:)
      @builders_by_schema[schema_type] ||= Array(with)
    end

    def coerce_type(type, with:)
      @builders_by_type[type] ||= Array(with)
    end

    def wrap(schema)
      wrapped_schema = schema.with_wrapped_subschemas(self)
      builders = builders_for_schema(schema)

      if builders.any?
        wrap_with_builders(wrapped_schema, builders)
      else
        wrapped_schema
      end
    end

    private

      def builders_for_schema(schema)
        @builders_by_schema.fetch(schema.class) do
          if schema.is_a?(Schemas::Type)
            @builders_by_type.fetch(schema.type, [])
          else
            []
          end
        end
      end

      def wrap_with_builders(schema, builders)
        coercers = builders.map{ |b| b.build(schema) }
        Schemas::Coercer.new(coercers, schema)
      end

  end
end
