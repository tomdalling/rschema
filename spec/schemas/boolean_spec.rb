RSpec.describe RSchema::Schemas::Boolean do
  subject { described_class.instance }

  it_behaves_like 'a schema'

  specify 'successful validation' do
    expect(validate(true)).to be_valid
    expect(validate(false)).to be_valid
  end

  specify 'failed validation' do
    result = validate(nil)

    expect(result).to be_invalid
    expect(result.error).to have_attributes(
      schema: subject,
      value: nil,
      symbolic_name: :not_a_boolean,
    )
  end

  specify '#with_wrapped_subschemas' do
    wrapped = subject.with_wrapped_subschemas(nil)
    expect(wrapped).to be(subject)
  end
end
