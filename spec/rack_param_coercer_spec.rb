require 'rschema/coercion_wrapper/rack_params'

RSpec.describe RSchema::CoercionWrapper::RACK_PARAMS do
  subject { described_class.wrap(schema) }
  let(:schema) do
    RSchema.define do
      fixed_hash(
        optional(:int) => _Integer,
        optional(:float) => _Float,
        optional(:symbol) => _Symbol,
        #optional(:bool) => boolean, # tested separately
        optional(:time) => _Time,
        optional(:date) => _Date,
        optional('string key') => _Integer,
        optional(:enum) => enum([:a, :b, :c]),
      )
    end
  end

  describe 'Integer coercion' do
    specify 'for strings' do
      result = validate(int: '5')
      expect(result.value).to eq(int: 5)
    end

    specify 'for nil' do
      result = validate(int: nil)
      expect(result.error[:int].symbolic_name).to eq(:coercion_failure)
    end
  end

  it 'coerces through Enum schemas' do
    result = validate(enum: 'a')
    expect(result.value).to eq(enum: :a)
  end

  describe 'Float coercion' do
    it 'coerces strings to Float' do
      result = validate(float: '5.6')
      expect(result.value).to eq(float: 5.6)
    end

    it 'fails for invalid strings' do
      result = validate(float: 'abc')
      expect(result).to be_invalid
    end
  end

  describe 'Symbol coercion' do
    it 'allows Symbols to pass though' do
      result = validate(symbol: :hello)
      expect(result.value).to eq(symbol: :hello)
    end

    it 'converts strings to Symbols' do
      result = validate(symbol: 'waka')
      expect(result.value).to eq(symbol: :waka)
    end

    it 'rejects all other types' do
      result = validate(symbol: 5)
      expect(result.error[:symbol].symbolic_name).to eq(:coercion_failure)
    end
  end

  describe 'Time coercion' do
    it 'allows Time values to pass through' do
      time = Time.new(2016, 12, 24, 18, 37, 43, '+11:00')
      result = validate(time: time)
      expect(result.value[:time]).to be(time)
    end

    it 'coerces strings with Time.parse' do
      dummy = Time.now
      expect(Time).to receive(:parse).with('waka').and_return(dummy)

      result = validate(time: 'waka')
      expect(result.value.fetch(:time)).to be(dummy)
    end

    it 'rejects non-iso8601 strings' do
      result = validate(time: '')
      expect(result.error[:time].symbolic_name).to eq(:coercion_failure)
    end

    it 'rejects all other types' do
      result = validate(time: 5)
      expect(result.error[:time].symbolic_name).to eq(:coercion_failure)
    end
  end

  describe 'Date coercion' do
    it 'coerces iso8601 strings to Date' do
      result = validate(date: '2016-12-25')
      expect(result.value).to eq(date: Date.new(2016, 12, 25))
    end

    it 'rejects non-iso8601 strings' do
      result = validate(date: '2016')
      expect(result.error[:date].symbolic_name).to eq(:coercion_failure)
    end

    it 'rejects all other types' do
      result = validate(date: 5)
      expect(result.error[:date].symbolic_name).to eq(:coercion_failure)
    end
  end

  describe 'FixedHash coercion' do
    it 'coerces keys from strings to symbols' do
      result = validate('int' => 5)
      expect(result.value).to eq(int: 5)
    end

    it 'does not coerce keys that are supposed to be strings' do
      result = validate('string key' => 5)
      expect(result.value).to eq('string key' => 5)
    end

    it 'removes extranous elements' do
      result = validate(123 => 4, wawawawawaw: 5)
      expect(result.value).to eq({})
    end
  end

  describe 'Boolean coercion' do
    subject { described_class.wrap(bool_schema) }
    let(:bool_schema) do
      RSchema.define_hash {{
        required: boolean,
        optional(:opt) => boolean,
      }}
    end

    it 'coerces magic strings to true' do
      ['1', 'True', 'On', 'Yes'].each do |truthy|
        result = validate(required: truthy)
        expect(result.value).to eq(required: true)
      end
    end

    it 'coerces magic strings to false' do
      ['0', 'False', 'Off', 'No'].each do |falsey|
        result = validate(required: falsey)
        expect(result.value).to eq(required: false)
      end
    end

    it 'coerces nil to false' do
      result = validate(required: nil)
      expect(result.value).to eq(required: false)
    end

    it 'defaults to false when the value is missing within a hash' do
      result = validate({})
      expect(result.value).to eq(required: false)
    end

    it 'allows true and false to pass through' do
      expect(validate(required: true)).to be_valid
      expect(validate(required: false)).to be_valid
    end

    it 'will not coerce unrecognised values' do
      result = validate(required: 'wakawaka')
      expect(result).to be_invalid
    end
  end

  it 'handles being wrapped twice' do
    twice_wrapped = WrapperStub.wrap(subject)

    result = twice_wrapped.call({
      int: '5',
      float: '6.7',
      symbol: 'wimble',
      date: '2017-01-27',
    }, RSchema::Options.default)

    expect(result.value).to eq(
      int: 5,
      float: 6.7,
      symbol: :wimble,
      date: Date.new(2017, 01, 27),
    )
  end
end
