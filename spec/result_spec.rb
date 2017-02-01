RSpec.describe RSchema::Result do
  it 'raises an error if you attempt to get the value when its invalid' do
    result = RSchema::Result.failure('wawawa')
    expect {
      result.value
    }.to raise_error(RSchema::Result::InvalidError)
  end
end
