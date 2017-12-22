class SchemaStub
  def self.for_valid_values(*valid_values)
    new do |input_value|
      if valid_values.include?(input_value)
        RSchema::Result.success(input_value)
      else
        RSchema::Result.failure
      end
    end
  end

  def self.for_mapping_values(mapping)
    new do |input_value|
      if mapping.key?(input_value)
        RSchema::Result.success(mapping.fetch(input_value))
      else
        RSchema::Result.failure
      end
    end
  end

  def self.that_always_succeeds
    new do |input_value|
      RSchema::Result.success(input_value)
    end
  end

  def self.that_always_fails
    new do
      RSchema::Result.failure
    end
  end

  def self.that_succeeds_where(&predicate)
    new do |input_value|
      if predicate.call(input_value)
        RSchema::Result.success(input_value)
      else
        RSchema::Result.failure
      end
    end
  end

  attr_reader :errors

  def initialize(&value_mapper)
    @received_values = []
    @errors = []
    @value_mapper = value_mapper
  end

  def call(value, options)
    @received_values << value

    result = @value_mapper.call(value)
    if result.valid?
      result
    else
      @errors << RSchema::Error.new(
        schema: self,
        value: value,
        symbolic_name: :schema_stub_error,
      )
      RSchema::Result.failure(@errors.last)
    end
  end

  def with_wrapped_subschemas(wrapper)
    self
  end

  def useless_method
    "yep, it's useless"
  end

  def has_received_value?(value)
    @received_values.include?(value)
  end

end
