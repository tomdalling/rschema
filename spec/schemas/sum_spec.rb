RSpec.describe RSchema::Schemas::Sum do
  subject { described_class.new([even_schema, positive_schema]) }
  let(:even_schema) { MockSchema.new(&:even?) }
  let(:positive_schema) { MockSchema.new(&:positive?) }

  it_behaves_like 'a schema'

  it 'passes validation if _any_ subschema is valid' do
    expect(subject.call(-6)).to be_valid
    expect(subject.call(5)).to be_valid
    expect(subject.call(6)).to be_valid
  end

  it 'fails validation if _none_ of the subschemas are valid' do
    result = subject.call(-5)

    expect(result).not_to be_valid
    expect(result.error).to have_attributes(
      schema: subject,
      value: -5,
      symbolic_name: 'rschema/alternation/all_invalid',
      vars: [even_schema.error, positive_schema.error],
    )
  end

  specify '#with_wrapped_subschemas' do
    wrapped = subject.with_wrapped_subschemas(MockWrapper)

    expect(wrapped).not_to be(subject)
    expect(wrapped).to be_a(described_class)
    expect(wrapped.subschemas).to all(be_a MockWrapper)
    expect(wrapped.subschemas.map(&:wrapped_subschema)).to eq([even_schema, positive_schema])
  end
end
