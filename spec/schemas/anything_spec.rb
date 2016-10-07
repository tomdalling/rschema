RSpec.describe RSchema::Schemas::Anything do
  subject{ described_class.instance }

  it 'always succeeds' do
    value = double
    result = subject.call(value)

    expect(result).to be_valid
    expect(result.value).to be(value)
  end
end
