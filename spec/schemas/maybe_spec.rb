RSpec.describe RSchema::Schemas::Maybe do
  subject { described_class.new(subschema) }
  let(:subschema) { MockSchema.new }

  it_behaves_like 'a schema'

  context 'successful validation' do
    it 'allows nil' do
      expect(subject.call(nil)).to be_valid
    end

    it 'otherwise delegates to the subschema' do
      expect(subject.call(:valid)).to be_valid
    end
  end

  specify 'failed validation' do
    result = subject.call(:wrong)

    expect(result).not_to be_valid
    expect(result.error).to be(subschema.error)
  end

  specify '#with_wrapped_subschemas' do
    wrapped = subject.with_wrapped_subschemas(MockWrapper)

    expect(wrapped.subschema).to be_a(MockWrapper)
    expect(wrapped.subschema.wrapped_subschema).to be(subschema)
  end
end
