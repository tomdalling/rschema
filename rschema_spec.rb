require_relative 'rschema'

RSpec.describe RSchema do
  describe '#validate' do
    it 'validates scalars' do
      schema = String
      expect(RSchema.validate(schema, 'Johnny')).to be(true)
      expect(RSchema.validate(schema, 5)).to be(false)
    end

    it 'validates arrays' do
      schema = [String]
      expect(RSchema.validate(schema, ['cat', 'bat'])).to be(true)
      expect(RSchema.validate(schema, [6, 'bat'])).to be(false)
    end

    it 'validates fixed-length arrays' do
      schema = [String, Integer]

      expect(RSchema.validate(schema, ['cat', 5])).to be(true)

      expect(RSchema.validate(schema, ['cat'])).to be(false)
      expect(RSchema.validate(schema, ['cat', 5, 'horse'])).to be(false)
    end

    it 'validates hashes (required keys)' do
      schema = {
        name: String,
        age: Integer,
      }

      expect(RSchema.validate(schema, name: 'Jimmy', age: 25)).to be(true)

      expect(RSchema.validate(schema, name: 'Jimmy', age: 25, extra: true)).to be(false)
      expect(RSchema.validate(schema, name: 5, age: 25)).to be(false)
      expect(RSchema.validate(schema, age: 25)).to be(false)
    end

    it 'validates optional hash keys' do
      schema = RSchema.schema {{
        required: String,
        _?(:optional) => String,
      }}

      expect(RSchema.validate(schema, required: 'hello')).to be(true)
      expect(RSchema.validate(schema, required: 'hello', optional: 'world')).to be(true)

      expect(RSchema.validate(schema, optional: 'world')).to be(false)
    end

    it 'handles arbitrary nesting' do
      schema = {
        list_name: String,
        list_items: [{
          item_id: Integer,
          item_name: String,
        }],
      }

      good_value = {
        list_name: 'Blog Posts',
        list_items: [
          {item_id: 1, item_name: 'Hello world'},
          {item_id: 3, item_name: 'Hello moon'},
          {item_id: 9, item_name: 'Hello sun'},
        ]
      }

      bad_value = {
        list_name: 'Blog Posts',
        list_items: [
          [1, 'Hello world'],
          [3, 'Hello moon'],
          [9, 'Hello sun'],
        ]
      }

      expect(RSchema.validate(schema, good_value)).to be(true)
      expect(RSchema.validate(schema, bad_value)).to be(false)
    end
  end

  describe '#coerce' do
    it 'coerces String => Integer' do
      expect(RSchema.coerce(Integer, '5')).to eq(5)
    end

    it 'coerces String => Float' do
      expect(RSchema.coerce(Float, '1.23')).to eq(1.23)
    end

    it 'coerces String => Symbol' do
      expect(RSchema.coerce(Symbol, 'hello')).to eq(:hello)
    end

    it 'coerces Symbol => String' do
      expect(RSchema.coerce(String, :hello)).to eq('hello')
    end

    it 'coerces Array => Set' do
      expect(RSchema.coerce(Set, [1, 2, 2, 3])).to eq(Set.new([1, 2, 3]))
    end

    it 'coerces Set => Array' do
      expect(RSchema.coerce(Array, Set.new([1, 2, 3]))).to contain_exactly(1, 2, 3)
    end

    it 'coerces String => DateTime' do
      expected = DateTime.new(2014, 9, 19, 20, 44, 40)
      expect(RSchema.coerce(DateTime, '2014-09-19T20:44:40+0000')).to eq(expected)
    end

    it 'coerces DateTime => String' do
      dt = DateTime.new(2014, 9, 19, 20, 44, 40, '+2')
      expect(RSchema.coerce(String, dt)).to eq('2014-09-19T20:44:40+02:00')
    end
  end
end
