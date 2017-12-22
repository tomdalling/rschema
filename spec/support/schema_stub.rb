class SchemaStub
  attr_reader :received_value

  def initialize(&validity_checker)
    @validity_checker = validity_checker
    @received_value = nil
  end

  def call(value, options)
    @received_value = value
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

  def useless_method
    "yep, it's useless"
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
