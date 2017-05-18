RSpec.describe RSchema::Schemas::Maybe do
  subject { described_class.new(subschema) }
  let(:subschema) { SchemaStub.new }

  it_behaves_like 'a schema'

  context 'successful validation' do
    it 'allows nil' do
      expect(validate(nil)).to be_valid
    end

    it 'otherwise delegates to the subschema' do
      expect(validate(:valid)).to be_valid
    end
  end

  specify 'failed validation' do
    result = validate(:wrong)

    expect(result).not_to be_valid
    expect(result.error).to be(subschema.error)
  end

  specify '#with_wrapped_subschemas' do
    wrapped = subject.with_wrapped_subschemas(WrapperStub)

    expect(wrapped.subschema).to be_a(WrapperStub)
    expect(wrapped.subschema.wrapped_subschema).to be(subschema)
  end
end
