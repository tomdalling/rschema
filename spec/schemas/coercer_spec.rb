RSpec.describe RSchema::Schemas::Coercer do
  subject { described_class.new(coercer, subschema) }
  let(:coercer) do
    CoercerStub.new { |value| Integer(value) }
  end
  let(:subschema) do
    SchemaStub.that_succeeds_where { |value| Integer === value && value.odd? }
  end

  it_behaves_like 'a schema'

  specify 'successful validation' do
    result = validate('5')

    expect(result).to be_valid
    expect(result.value).to eq(5)
  end

  describe 'failed validation' do
    specify 'due to coercion failure' do
      result = validate('abc')

      expect(subschema).to have_received_value('abc')
      expect(result).not_to be_valid
      expect(result.error).to be(subschema.errors.last)
    end

    specify 'due to subschema failure' do
      result = validate('6')

      expect(subschema).to have_received_value(6)
      expect(result).not_to be_valid
      expect(result.error).to be(subschema.errors.last)
    end
  end

  specify '#with_wrapped_subschemas' do
    wrapped = subject.with_wrapped_subschemas(WrapperStub)
    expect(wrapped).to be_a(described_class)
    expect(wrapped).not_to be(subject)
    expect(wrapped.subschema).to be_a(WrapperStub)
    expect(wrapped.subschema.wrapped_subschema).to be(subschema)
  end
end
