RSpec.describe RSchema::Schemas::VariableLengthArray do
  subject { described_class.new(subschema) }
  let(:subschema) { SchemaStub.new }

  it_behaves_like 'a schema'

  specify 'successful validation' do
    result = subject.call([:valid, :valid, :valid])

    expect(result).to be_valid
    expect(result.value).to eq([:valid, :valid, :valid])
  end

  context 'failed validation' do
    specify 'due to value not being an array' do
      result = subject.call(5)

      expect(result).not_to be_valid
      expect(result.error).to have_attributes(
        schema: subject,
        value: 5,
        symbolic_name: 'not_an_array',
      )
    end

    specify 'due to subchema failure' do
      result = subject.call([:wrong, :valid, :wrong])

      expect(result).not_to be_valid
      expect(result.error).to eq({
        0 => subschema.error,
        2 => subschema.error,
      })
    end

    it 'respects the `fail_fast` option' do
      options = RSchema::Options.new(fail_fast: true)

      result = subject.call([:valid, :wrong, :wrong], options)

      expect(result).not_to be_valid
      expect(result.error).to eq({ 1 => subschema.error })
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
