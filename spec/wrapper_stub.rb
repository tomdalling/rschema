class WrapperStub
  def self.wrap(schema)
    new(schema)
  end

  attr_reader :wrapped_subschema

  def initialize(wrapped_subschema)
    @wrapped_subschema = wrapped_subschema
  end
end
