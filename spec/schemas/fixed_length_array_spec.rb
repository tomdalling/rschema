RSpec.describe RSchema::Schemas::FixedLengthArray do
  let(:subschema1) { MockSchema.new }
  let(:subschema2) { MockSchema.new }
  subject { described_class.new([subschema1, subschema2]) }

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
        symbolic_name: 'rschema/fixed_length_array/not_an_array',
      )
    end

    specify 'due to incorrect number of elements' do
      result = subject.call([])

      expect(result).not_to be_valid
      expect(result.error).to have_attributes(
        schema: subject,
        value: [],
        symbolic_name: 'rschema/fixed_length_array/incorrect_size',
      )
    end

    specify 'due to subschema failure' do
      result = subject.call([:wrong, :wrong_again])

      expect(result).not_to be_valid
      expect(result.error).to eq({
        0 => subschema1.error,
        1 => subschema2.error,
      })
    end

    it 'respects the `fail_fast` option' do
      options = RSchema::Options.new(fail_fast: true)

      result = subject.call([:wrong, :wrong_again], options)

      expect(result.error).to eq({ 0 => subschema1.error })
    end
  end
end
