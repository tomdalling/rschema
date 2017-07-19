# frozen_string_literal: true

class WrapperStub
  def self.wrap(schema, recursive = false)
    new(recursive ? schema.with_wrapped_subschemas(self) : schema)
  end

  attr_reader :wrapped_subschema

  def initialize(wrapped_subschema)
    @wrapped_subschema = wrapped_subschema
  end

  def call(*args)
    @wrapped_subschema.call(*args)
  end
end
