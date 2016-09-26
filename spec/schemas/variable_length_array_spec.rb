require 'rschema/schemas/variable_length_array'

RSpec.describe RSchema::Schemas::VariableLengthArray do
  let(:subschema) { MockSchema.new }
  subject(:schema) { described_class.new(subschema) }

  specify 'successful validation' do
    result = schema.call([:valid, :valid, :valid])

    expect(result).to be_valid
    expect(result.value).to eq([:valid, :valid, :valid])
  end

  context 'failed validation' do
    specify 'due to value not being an array' do
      result = schema.call(5)

      expect(result).not_to be_valid
      expect(result.error).to have_attributes(
        schema: schema,
        value: 5,
        symbolic_name: 'rschema/array_of/not_an_array',
      )
    end

    specify 'due to subchema failure' do
      result = schema.call([:wrong, :valid, :wrong])

      expect(result).not_to be_valid
      expect(result.error).to eq({
        0 => subschema.error,
        2 => subschema.error,
      })
    end

    it 'respects the `fail_fast` option' do
      options = RSchema::Options.new(fail_fast: true)

      result = schema.call([:valid, :wrong, :wrong], options)

      expect(result).not_to be_valid
      expect(result.error).to eq({ 1 => subschema.error })
    end
  end

  specify '#with_wrapped_subschemas' do
    wrapped = schema.with_wrapped_subschemas(MockWrapper)

    expect(wrapped).not_to be(schema)
    expect(wrapped).to be_a(described_class)
    expect(wrapped.element_schema).to be_a(MockWrapper)
    expect(wrapped.element_schema.wrapped_subschema).to be(subschema)
  end
end
