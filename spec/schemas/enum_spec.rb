RSpec.describe RSchema::Schemas::Enum do
  subject { described_class.new([:a, :b, :c]) }

  it_behaves_like 'a schema'

  specify 'successful validation' do
    result = subject.call(:b)

    expect(result).to be_valid
    expect(result.value).to eq(:b)
  end

  specify 'failed validation' do
    result = subject.call(:z)

    expect(result).not_to be_valid
    expect(result.error).to have_attributes(
      schema: subject,
      value: :z,
      symbolic_name: 'not_a_member',
    )
  end

  specify '#with_wrapped_subschemas' do
    wrapped = subject.with_wrapped_subschemas(nil)
    expect(wrapped).to be(subject)
  end
end
