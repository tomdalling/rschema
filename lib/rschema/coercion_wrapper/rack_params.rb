module RSchema
class CoercionWrapper

  RACK_PARAMS = CoercionWrapper.new do
    coerce_type Symbol, with: Coercers::Symbol
    coerce_type Integer, with: Coercers::Integer
    coerce_type Float, with: Coercers::Float
    coerce_type Time, with: Coercers::Time
    coerce_type Date, with: Coercers::Date

    coerce Schemas::Maybe, with: Coercers::NilEmptyStrings
    coerce Schemas::Boolean, with: Coercers::Boolean
    coerce Schemas::FixedHash, with: Coercers::Chain[
      Coercers::FixedHash::SymbolizeKeys,
      Coercers::FixedHash::RemoveExtraneousAttributes,
      Coercers::FixedHash::DefaultBooleansToFalse,
      Coercers::FixedHash::DefaultArraysToEmpty,
    ]
  end

end
end

