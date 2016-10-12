RSpec.describe RSchema::Schemas::Type do
  subject(:schema) { described_class.new(Enumerable) }

  it_behaves_like 'a schema'

  it 'gives a valid result with the value.is_a?(type)' do
    result = schema.call([])

    expect(result).to be_valid
    expect(result.value).to eq([])
  end

  it 'gives an invalid result when not value.is_a?(type)' do
    result = schema.call(5)

    expect(result).not_to be_valid
    expect(result.error).to have_attributes(
      schema: schema,
      value: 5,
      symbolic_name: 'wrong_type',
    )
  end

  specify '#with_wrapped_subschemas' do
    expect(subject.with_wrapped_subschemas(nil)).to be(subject)
  end
end
