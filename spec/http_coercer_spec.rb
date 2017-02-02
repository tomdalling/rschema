RSpec.describe RSchema::HTTPCoercer do
  subject { described_class.wrap(schema) }
  let(:schema) do
    RSchema.define do
      Hash(
        optional(:int) => _Integer,
        optional(:float) => _Float,
        optional(:symbol) => _Symbol,
        #optional(:bool) => Boolean(), # tested seperately
        optional(:time) => _Time,
        optional(:date) => _Date,
        optional('string key') => _Integer,
        optional(:enum) => enum([:a, :b, :c]),
      )
    end
  end

  it 'coerces strings to Integer' do
    result = subject.call(int: '5')
    expect(result.value).to eq(int: 5)
  end

  it 'coerces through Enum schemas' do
    result = subject.call(enum: 'a')
    expect(result.value).to eq(enum: :a)
  end

  describe 'Float coercion' do
    it 'coerces strings to Float' do
      result = subject.call(float: '5.6')
      expect(result.value).to eq(float: 5.6)
    end

    it 'fails for invalid strings' do
      result = subject.call(float: 'abc')
      expect(result).to be_invalid
    end
  end

  describe 'Symbol coercion' do
    it 'allows Symbols to pass though' do
      result = subject.call(symbol: :hello)
      expect(result.value).to eq(symbol: :hello)
    end

    it 'converts strings to Symbols' do
      result = subject.call(symbol: 'waka')
      expect(result.value).to eq(symbol: :waka)
    end

    it 'rejects all other types' do
      result = subject.call(symbol: 5)
      expect(result.error[:symbol].symbolic_name).to eq(:coercion_failure)
    end
  end

  describe 'Time coercion' do
    it 'allows Time values to pass through' do
      time = Time.new(2016, 12, 24, 18, 37, 43, '+11:00')
      result = subject.call(time: time)
      expect(result.value[:time]).to be(time)
    end

    it 'coerces iso8601 strings to Time' do
      result = subject.call(time: '2016-12-24T18:37:43+11:00')
      expect(result.value).to eq(time: Time.new(2016, 12, 24, 18, 37, 43, '+11:00'))
    end

    it 'rejects non-iso8601 strings' do
      result = subject.call(time: '23rd July 2016')
      expect(result.error[:time].symbolic_name).to eq(:coercion_failure)
    end

    it 'rejects all other types' do
      result = subject.call(time: 5)
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

    it 'rejects all other types' do
      result = subject.call(date: 5)
      expect(result.error[:date].symbolic_name).to eq(:coercion_failure)
    end
  end

  describe 'FixedHash coercion' do
    it 'coerces keys from strings to symbols' do
      result = subject.call('int' => 5)
      expect(result.value).to eq(int: 5)
    end

    it 'does not coerce keys that are supposed to be strings' do
      result = subject.call('string key' => 5)
      expect(result.value).to eq('string key' => 5)
    end

    it 'removes extranous elements' do
      result = subject.call(123 => 4, wawawawawaw: 5)
      expect(result.value).to eq({})
    end
  end

  describe 'Boolean coercion' do
    subject(:bool_subject) { described_class.wrap(bool_schema) }
    let(:bool_schema) do
      RSchema.define_hash {{
        required: Boolean(),
        optional(:opt) => Boolean(),
      }}
    end

    it 'coerces magic strings to true' do
      ['1', 'True', 'On'].each do |truthy|
        result = bool_subject.call(required: truthy)
        expect(result.value).to eq(required: true)
      end
    end

    it 'coerces magic strings to false' do
      ['0', 'False', 'Off'].each do |falsey|
        result = bool_subject.call(required: falsey)
        expect(result.value).to eq(required: false)
      end
    end

    it 'coerces nil to false' do
      result = bool_subject.call(required: nil)
      expect(result.value).to eq(required: false)
    end

    it 'defaults to false when the value is missing within a hash' do
      result = bool_subject.call({})
      expect(result.value).to eq(required: false)
    end

    it 'allows true and false to pass through' do
      expect(bool_subject.call(required: true)).to be_valid
      expect(bool_subject.call(required: false)).to be_valid
    end

    it 'will not coerce unrecognised values' do
      result = bool_subject.call(required: 'wakawaka')
      expect(result).to be_invalid
    end
  end

  it 'handles being wrapped twice' do
    twice_wrapped = WrapperStub.wrap(subject)

    result = twice_wrapped.call(
      int: '5',
      float: '6.7',
      symbol: 'wimble',
      date: '2017-01-27',
    )

    expect(result.value).to eq(
      int: 5,
      float: 6.7,
      symbol: :wimble,
      date: Date.new(2017, 01, 27),
    )
  end
end
