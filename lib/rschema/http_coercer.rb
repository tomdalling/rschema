module RSchema
  RACK_PARAM_COERCER = CoercionWrapper.new do
    coerce_type Symbol, with: Coercers::Symbol
    coerce_type Integer, with: Coercers::Integer
    coerce_type Float, with: Coercers::Float
    coerce_type Time, with: Coercers::Time
    coerce_type Date, with: Coercers::Date

    coerce Schemas::Boolean, with: Coercers::Boolean
    coerce Schemas::FixedHash, with: [
      Coercers::FixedHash::SymbolizeKeys,
      Coercers::FixedHash::RemoveExtraneousAttributes,
      Coercers::FixedHash::DefaultBooleansToFalse,
    ]
  end
end

