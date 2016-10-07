RSpec.describe RSchema::Schemas::Chain do
  subject { described_class.new([first_subschema, last_subschema]) }
  let(:first_subschema) { double }
  let(:last_subschema) { double }
  let(:options) { RSchema::Options.default }

  it 'gives a valid result if _all_ subschemas give a valid result' do
    expect(first_subschema).to receive(:call).and_return(RSchema::Result.success(nil))
    expect(last_subschema).to receive(:call).and_return(RSchema::Result.success(nil))

    result = subject.call(123)

    expect(result).to be_valid
  end

  it 'passes the results of each subschema to the next subschema' do
    expect(first_subschema).to receive(:call)
      .with('larry', options)
      .and_return(RSchema::Result.success('curly'))
    expect(last_subschema).to receive(:call)
      .with('curly' , options)
      .and_return(RSchema::Result.success('moe'))

    result = subject.call('larry', options)

    expect(result).to be_valid
    expect(result.value).to eq('moe')
  end

  it 'gives an invalid result if _any_ subschema gives an invalid result' do
    error = double
    expect(first_subschema).to receive(:call).and_return(RSchema::Result.success(nil))
    expect(last_subschema).to receive(:call).and_return(RSchema::Result.failure(error))

    result = subject.call(123)

    expect(result).not_to be_valid
    expect(result.error).to be(error)
  end

  specify '#with_wrapped_subschemas' do
    wrapped = subject.with_wrapped_subschemas(MockWrapper)

    expect(wrapped).not_to be(subject)
    expect(wrapped.subschemas).to all(be_a MockWrapper)
    expect(wrapped.subschemas.map(&:wrapped_subschema)).to eq([first_subschema, last_subschema])
  end
end

