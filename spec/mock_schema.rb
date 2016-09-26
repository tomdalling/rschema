class MockSchema
  def call(value, options)
    if value == :valid
      RSchema::Result.success(value)
    else
      RSchema::Result.failure(error)
    end
  end

  def with_wrapped_subschemas
    self
  end

  def error
    @error ||= RSchema::Error.new(
      schema: self,
      value: :mock_value,
      symbolic_name: 'mock_error',
    )
  end
end
