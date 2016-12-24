RSpec.describe RSchema do
  it 'provides schema-based validation of arbitrary data structures' do
    int_schema = RSchema.define { _Integer }

    valid_result = int_schema.call(5)
    expect(valid_result).to be_valid

    invalid_result = int_schema.call('hello')
    expect(invalid_result).not_to be_valid
  end

  it 'provides details when values are not valid' do
    array_of_symbols = RSchema.define { Array(_Symbol) }

    result = array_of_symbols.call([:a, :b, 'see'])
    expect(result).not_to be_valid

    error = result.error[2]
    expect(error).to be_a(RSchema::Error)
    expect(error.schema.type).to be(Symbol)
    expect(error.symbolic_name).to eq('wrong_type')
    expect(error.value).to eq('see')
  end

  it 'provides coercion' do
    array_of_symbols = RSchema.define { Array(_Symbol) }
    coercer = RSchema::HTTPCoercer.wrap(array_of_symbols)
    options = RSchema::Options.default

    result = coercer.call(['a', :b, 'c'], options)

    expect(result).to be_valid
    expect(result.value).to eq([:a, :b, :c])
  end

  context 'Complicated, nested schemas and values' do
    let(:user_schema) do
      RSchema.define do
        Hash(
          name: _String,
          optional(:age) => _Integer,
          email: maybe(_String),
          role: enum([:journalist, :editor, :administrator]),
          enabled: Boolean(),
          rating: either(_Integer, _Float),
          alternate_names: Array(_String),
          gps_coordinates: Array(_Float, _Float),
          favourite_even_number: pipeline(_Integer, predicate(&:even?)),
          animals: Set(_Symbol),
          whatever: anything,
          cakes_by_date: VariableHash(_Date => _String),
        )
      end
    end

    let(:valid_user) do
      {
        name: 'Tom',
        email: nil,
        role: :administrator,
        enabled: true,
        rating: 5.2,
        alternate_names: ['Thomas', 'Dowl'],
        gps_coordinates: [123.456, 876.654],
        favourite_even_number: 12,
        whatever: "this could be literally any value",
        animals: Set.new([:dog, :cat]),
        cakes_by_date: {
          Date.new(2014, 6, 22) => 'Black Forest Cake',
          Date.new(2015, 7, 23) => 'Mud Cake',
          Date.new(2016, 8, 24) => 'Passionfruit Cheesecake',
        },
      }
    end

    it 'handles valid values' do
      result = user_schema.call(valid_user)
      expect(result).to be_valid
    end

    it 'handles invalid values' do
      invalid_user = valid_user.merge(gps_coordinates: [123.45, 'wrong!'])

      result = user_schema.call(invalid_user)

      expect(result).not_to be_valid
      expect(result.error[:gps_coordinates][1]).to have_attributes({
        value: 'wrong!',
        symbolic_name: 'wrong_type',
      })
    end

    it 'handles coercion' do
      user_coercer = RSchema::HTTPCoercer.wrap(user_schema)
      input = valid_user.merge(rating: '6.7')

      result = user_coercer.call(input)

      expect(result).to be_valid
      expect(result.value[:rating]).to eq(6.7)
    end
  end
end
