RSpec.describe RSchema::Schemas::FixedLengthArray do
  subject { described_class.new([first_subschema, last_subschema]) }
  let(:first_subschema) { SchemaStub.new }
  let(:last_subschema) { SchemaStub.new }

  it_behaves_like 'a schema'

  specify 'successful validation' do
    result = subject.call([:valid, :valid])

    expect(result).to be_valid
    expect(result.value).to eq([:valid, :valid])
  end

  context 'failed validation' do
    specify 'due to not being an array' do
      result = subject.call(6)

      expect(result).not_to be_valid
      expect(result.error).to have_attributes(
        schema: subject,
        value: 6,
        symbolic_name: 'not_an_array',
      )
    end

    specify 'due to incorrect number of elements' do
      result = subject.call([])

      expect(result).not_to be_valid
      expect(result.error).to have_attributes(
        schema: subject,
        value: [],
        symbolic_name: 'incorrect_size',
      )
    end

    specify 'due to subschema failure' do
      result = subject.call([:wrong, :wrong_again])

      expect(result).not_to be_valid
      expect(result.error).to eq({
        0 => first_subschema.error,
        1 => last_subschema.error,
      })
    end

    it 'respects the `fail_fast` option' do
      options = RSchema::Options.new(fail_fast: true)

      result = subject.call([:wrong, :wrong_again], options)

      expect(result.error).to eq({ 0 => first_subschema.error })
    end
  end

  specify '#with_wrapped_subschemas' do
    wrapped = subject.with_wrapped_subschemas(WrapperStub)
    subschemas = wrapped.subschemas

    expect(subschemas).to all(be_a WrapperStub)
    expect(subschemas.map(&:wrapped_subschema)).to eq([first_subschema, last_subschema])
  end
end

