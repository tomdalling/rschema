RSpec.describe RSchema::Schemas::Anything do
  subject{ described_class.instance }

  it_behaves_like 'a schema'

  it 'always succeeds' do
    value = double
    result = subject.call(value)

    expect(result).to be_valid
    expect(result.value).to be(value)
  end

  specify '#with_wrapped_subschemas' do
    wrapped = subject.with_wrapped_subschemas(MockWrapper)
    expect(wrapped).to be(subject)
  end
end
