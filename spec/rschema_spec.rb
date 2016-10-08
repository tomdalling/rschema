RSpec.describe RSchema do
  example 'RSchema provides schema-based validation' do
    int_schema = RSchema.define { _Integer }

    valid_result = int_schema.call(5)
    expect(valid_result).to be_valid

    invalid_result = int_schema.call('hello')
    expect(invalid_result).not_to be_valid
  end

  example 'RSchema provides details when values are not valid' do
    symbol_array_schema = RSchema.define { Array(_Symbol) }

    result = symbol_array_schema.call([:a, :b, 'see'])
    expect(result).not_to be_valid
    expect(result.error).to be_a(Hash)
    expect(result.error).to have_key(2)

    error = result.error[2]
    expect(error).to be_a(RSchema::Error)
    expect(error.schema).to be_a(RSchema::Schemas::Type)
    expect(error.value).to eq('see')
    expect(error.symbolic_name).to eq('rschema/type/invalid')
  end

  example 'RSchema provides coercion' do
    symbol_array_schema = RSchema.define { Array(_Symbol) }
    coercer = RSchema::HTTPCoercer.wrap(symbol_array_schema)

    result = coercer.call(['a', :b, 'c'])

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
          role: enum(:journalist, :editor, :administrator),
          enabled: Boolean(),
          rating: either(_Integer, _Float),
          alternate_names: Array(_String),
          gps_coordinates: Array(_Float, _Float),
          favourite_even_number: pipeline(_Integer, predicate(&:even?)),
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
        symbolic_name: 'rschema/type/invalid',
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
