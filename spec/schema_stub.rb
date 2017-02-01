class SchemaStub
  def initialize(&validity_checker)
    @validity_checker = validity_checker
  end

  def call(value, options=nil)
    if valid?(value)
      RSchema::Result.success(value)
    else
      RSchema::Result.failure(error)
    end
  end

  def with_wrapped_subschemas(wrapper)
    self
  end

  def error
    @error ||= RSchema::Error.new(
      schema: self,
      value: :mock_value,
      symbolic_name: :mock_error,
    )
  end

  private

    def valid?(value)
      if @validity_checker
        @validity_checker.call(value)
      else
        value == :valid
      end
    end

end
