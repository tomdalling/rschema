RSpec.describe RSchema::Schemas::Boolean do
  subject { described_class.instance }

  it_behaves_like 'a schema'

  specify 'successful validation' do
    expect(subject.call(true)).to be_valid
    expect(subject.call(false)).to be_valid
  end

  specify 'failed validation' do
    result = subject.call(nil)

    expect(result).to be_invalid
    expect(result.error).to have_attributes(
      schema: subject,
      value: nil,
      symbolic_name: 'rschema/boolean/invalid',
    )
  end

  specify '#with_wrapped_subschemas' do
    wrapped = subject.with_wrapped_subschemas(nil)
    expect(wrapped).to be(subject)
  end
end
