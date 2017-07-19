# frozen_string_literal: true

module RSchema
  #
  # Builds coercing schemas, by wrapping coercers around an existing schema.
  #
  class CoercionWrapper
    def initialize(&initializer)
      @builder_by_schema = {}
      @builder_by_type = {}
      instance_eval(&initializer) if initializer
    end

    def coerce(schema_type, with:)
      @builder_by_schema[schema_type] = with
    end

    def coerce_type(type, with:)
      @builder_by_type[type] = with
    end

    def wrap(schema)
      wrapped_schema = schema.with_wrapped_subschemas(self)
      wrap_with_coercer(wrapped_schema)
    end

    private

    def builder_for_schema(schema)
      @builder_by_schema.fetch(schema.class) do
        builder_for_type(schema.type) if schema.is_a?(Schemas::Type)
      end
    end

    def builder_for_type(type)
      # polymorphic lookup
      type.ancestors.each do |ancestor|
        builder = @builder_by_type[ancestor]
        return builder if builder
      end

      nil
    end

    def wrap_with_coercer(schema)
      builder = builder_for_schema(schema)
      if builder
        coercer = builder.build(schema)
        Schemas::Coercer.new(coercer, schema)
      else
        schema
      end
    end
  end
end
