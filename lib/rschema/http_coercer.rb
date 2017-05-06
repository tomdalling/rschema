module RSchema
  HTTPCoercer = CoercionWrapper.new do
    coerce_schemas(
      Schemas::Boolean => Coercers::Boolean,
      Schemas::FixedHash => Coercers::HTTP::ParamHash,
    )

    coerce_types(
      Symbol => Coercers::Symbol,
      Integer => Coercers::Integer,
      Float => Coercers::Float,
      Time => Coercers::Time,
      Date => Coercers::Date,
    )
  end
end
