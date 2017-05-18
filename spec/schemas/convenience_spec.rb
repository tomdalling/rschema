RSpec.describe RSchema::Schemas::Convenience do
  subject { described_class.new(subschema) }
  let(:subschema) { SchemaStub.new }

  specify '#validate' do
    expect(subschema)
      .to receive(:call)
      .with(5, RSchema::Options.default)
      .and_return(:yep)

    result = subject.validate(5)

    expect(result).to eq(:yep)
  end

  describe '#validate!' do
    it 'when valid, returns the result value' do
      result = subject.validate!(:valid)
      expect(result).to eq(:valid)
    end

    it 'when invalid, raises a RSchema::Invalid containing the error' do
      expect{ subject.validate!('invalid') }.to raise_error do |ex|
        expect(ex).to be_a(RSchema::Invalid)
        expect(ex.validation_error).to be(subschema.error)
      end
    end
  end

  specify '#valid?' do
    expect(subject.valid?(:valid)).to be(true)
    expect(subject.valid?('wrong')).to be(false)
  end

  it 'delegates methods calls to the raw schema' do
    expect(subject.useless_method).to eq("yep, it's useless")
  end

  specify '.unwrap' do
    multiwrapped = described_class.new(
      described_class.new(
        described_class.new(subschema)
      )
    )
    expect(described_class.unwrap(multiwrapped)).to be(subschema)
  end

  describe '.wrap' do
    it "wraps a schema with #{described_class}" do
      wrapped = described_class.wrap(subschema)
      expect(wrapped).to be_a(described_class)
      expect(wrapped.raw_schema).to be(subschema)
    end

    it 'does not wrap already-wrapped schemas' do
      expect(described_class.wrap(subject)).to be(subject)
    end
  end

  specify '#with_wrapped_subschemas' do
    wrapped = subject.with_wrapped_subschemas(WrapperStub)
    expect(wrapped.raw_schema).to be_a(WrapperStub)
    expect(wrapped.raw_schema.wrapped_subschema).to be(subschema)
  end
end
