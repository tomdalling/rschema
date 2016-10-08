RSpec.describe RSchema::Schemas::Predicate do
  subject { described_class.new(predicate) }
  let(:predicate) { ->(x){ x.even? } }

  it_behaves_like 'a schema'

  it 'gives a valid result if the predicate passes' do
    expect(subject.call(4)).to be_valid
  end

  it 'gives an invalid result if the predicate fails' do
    result = subject.call(5)

    expect(result).not_to be_valid
    expect(result.error).to have_attributes(
      schema: subject,
      value: 5,
      symbolic_name: 'rschema/predicate/false',
    )
  end

  specify '#with_wrapped_subschemas' do
    wrapped = subject.with_wrapped_subschemas(MockWrapper)
    expect(wrapped).to be(subject)
  end
end
