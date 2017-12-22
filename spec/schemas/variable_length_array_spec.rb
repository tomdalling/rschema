RSpec.describe RSchema::Schemas::VariableLengthArray do
  subject { described_class.new(subschema) }
  let(:subschema) { SchemaStub.for_valid_values(:valid) }

  it_behaves_like 'a schema'

  specify 'successful validation' do
    result = validate([:valid, :valid, :valid])

    expect(result).to be_valid
    expect(result.value).to eq([:valid, :valid, :valid])
  end

  context 'failed validation' do
    specify 'due to value not being an array' do
      result = validate(5)

      expect(result).not_to be_valid
      expect(result.error).to have_attributes(
        schema: subject,
        value: 5,
        symbolic_name: :not_an_array,
      )
    end

    specify 'due to subchema failure' do
      result = validate([:wrong, :valid, :wrong])

      expect(result).not_to be_valid
      expect(result.error).to eq({
        0 => subschema.errors.first,
        2 => subschema.errors.last,
      })
    end

    it 'respects the `fail_fast` option' do
      options = RSchema::Options.new(fail_fast: true)

      result = validate([:valid, :wrong, :wrong], options)

      expect(result).not_to be_valid
      expect(result.error).to eq({ 1 => subschema.errors.last })
    end
  end

  specify '#with_wrapped_subschemas' do
    wrapped = subject.with_wrapped_subschemas(WrapperStub)

    expect(wrapped).not_to be(subject)
    expect(wrapped).to be_a(described_class)
    expect(wrapped.element_schema).to be_a(WrapperStub)
    expect(wrapped.element_schema.wrapped_subschema).to be(subschema)
  end
end
