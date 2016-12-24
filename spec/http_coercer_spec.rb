RSpec.describe RSchema::HTTPCoercer do
  subject { described_class.wrap(schema) }
  let(:schema) do
    RSchema.define do
      Hash(
        optional(:int) => _Integer,
        optional(:float) => _Float,
        optional(:symbol) => _Symbol,
        optional(:bool) => Boolean(),
        optional(:time) => _Time,
        optional(:date) => _Date,
        optional('string key') => _Integer,
      )
    end
  end

  it 'coerces strings to Integer' do
    result = subject.call(int: '5')
    expect(result.value).to eq(int: 5)
  end

  it 'coerces strings to Float' do
    result = subject.call(float: '5.6')
    expect(result.value).to eq(float: 5.6)
  end

  it 'coerces strings to Symbol' do
    result = subject.call(symbol: 'waka')
    expect(result.value).to eq(symbol: :waka)
  end

  describe 'Time coercion' do
    it 'coerces iso8601 strings to Time' do
      result = subject.call(time: '2016-12-24T18:37:43+11:00')
      expect(result.value).to eq(time: Time.new(2016, 12, 24, 18, 37, 43, '+11:00'))
    end

    it 'rejects non-iso8601 strings' do
      result = subject.call(time: '23rd July 2016')
      expect(result.error[:time].symbolic_name).to eq(:coercion_failure)
    end
  end

  describe 'Date coercion' do
    it 'coerces iso8601 strings to Date' do
      result = subject.call(date: '2016-12-25')
      expect(result.value).to eq(date: Date.new(2016, 12, 25))
    end

    it 'rejects non-iso8601 strings' do
      result = subject.call(date: '2016')
      expect(result.error[:date].symbolic_name).to eq(:coercion_failure)
    end
  end

  describe 'FixedHash key symbolization' do
    it 'coerces fixed hash keys from strings to symbols' do
      result = subject.call('int' => 5)
      expect(result.value).to eq(int: 5)
    end

    it 'does not affect keys that are supposed to be strings' do
      result = subject.call('string key' => 5)
      expect(result.value).to eq('string key' => 5)
    end
  end

  #TODO: check what values browsers actually send for checkboxes.
  #      this is probably totally wrong
  describe 'Boolean coercion' do
    it 'coerces magic strings to true' do
      ['1', 'True'].each do |truthy|
        result = subject.call(bool: truthy)
        expect(result.value).to eq(bool: true)
      end
    end

    it 'coerces magic strings to false' do
      ['0', 'False'].each do |falsey|
        result = subject.call(bool: falsey)
        expect(result.value).to eq(bool: false)
      end
    end

    it 'will not coerce unrecognised values' do
      result = subject.call(bool: 'wakawaka')
      expect(result).to be_invalid
    end
  end
end
