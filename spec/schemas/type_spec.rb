require 'rschema/schemas/type'

RSpec.describe RSchema::Schemas::Type do
  subject(:schema) { described_class.new(Enumerable) }

  specify 'successful validation' do
    result = schema.call([])

    expect(result).to be_valid
    expect(result.value).to eq([])
  end

  specify 'failed validation' do
    result = schema.call(5)

    expect(result).not_to be_valid
    expect(result.error).to have_attributes(
      schema: schema,
      value: 5,
      symbolic_name: 'rschema/type/invalid',
    )
  end

  specify '#with_wrapped_subschemas' do
    expect(subject.with_wrapped_subschemas(nil)).to be(subject)
  end
end
