require 'rschema/coercion_wrapper/rack_params'

RSpec.describe RSchema do
  it 'provides schema-based validation of arbitrary data structures' do
    int_schema = RSchema.define { _Integer }

    valid_result = int_schema.validate(5)
    expect(valid_result).to be_valid

    invalid_result = int_schema.validate('hello')
    expect(invalid_result).not_to be_valid
  end

  it 'provides details when values are not valid' do
    array_of_symbols = RSchema.define { array(_Symbol) }

    result = array_of_symbols.validate([:a, :b, 'see'])
    expect(result).not_to be_valid

    error = result.error[2]
    expect(error).to be_a(RSchema::Error)
    expect(error.schema.type).to be(Symbol)
    expect(error.symbolic_name).to eq(:wrong_type)
    expect(error.value).to eq('see')
  end

  it 'provides coercion' do
    array_of_symbols = RSchema.define { array(_Symbol) }
    coercer = RSchema::CoercionWrapper::RACK_PARAMS.wrap(array_of_symbols)

    result = coercer.validate(['a', :b, 'c'])

    expect(result).to be_valid
    expect(result.value).to eq([:a, :b, :c])
  end

  specify '#define_hash' do
    schema = RSchema.define_hash{{ name: _String }}

    result = schema.validate({ name: 'Tom' })

    expect(result).to be_valid
  end

  specify '#define_predicate' do
    schema = RSchema.define_predicate('even') { |x| x.even? }

    result = schema.validate(5)

    expect(result).not_to be_valid
    expect(result.error.schema.name).to eq('even')
  end

  context 'Complicated, nested schemas and values' do
    let(:user_schema) do
      RSchema.define do
        hash(
          name: _String,
          optional(:age) => _Integer,
          email: maybe(_String),
          role: enum([:journalist, :editor, :administrator]),
          enabled: boolean(),
          rating: either(_Integer, _Float),
          alternate_names: array(_String),
          gps_coordinates: array(_Float, _Float),
          favourite_even_number: pipeline(_Integer, predicate('even', &:even?)),
          animals: set(_Symbol),
          whatever: anything,
          cakes_by_date: variable_hash(_Date => _String),
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
      result = user_schema.validate(valid_user)
      expect(result).to be_valid
    end

    it 'handles invalid values' do
      invalid_user = valid_user.merge(gps_coordinates: [123.45, 'wrong!'])

      result = user_schema.validate(invalid_user)

      expect(result).not_to be_valid
      expect(result.error[:gps_coordinates][1]).to have_attributes({
        value: 'wrong!',
        symbolic_name: :wrong_type,
      })
    end

    it 'handles coercion' do
      user_coercer = RSchema::CoercionWrapper::RACK_PARAMS.wrap(user_schema)
      input = valid_user.merge(rating: '6.7')

      result = user_coercer.validate(input)

      expect(result).to be_valid
      expect(result.value[:rating]).to eq(6.7)
    end

    it 'allows creation of new schemas based on existing ones' do
      new_user_schema = RSchema.define do
        user_schema.merge(attributes(
          wigwam: _String,
        ))
      end

      result = new_user_schema.validate(valid_user.merge(wigwam: 'teepee'))

      expect(result).to be_valid
      expect(result.value[:wigwam]).to eq('teepee')
    end
  end

  describe 'custom DSL methods' do
    module MyCustomMethods
      def modern_major_general
        :penzance
      end
    end

    it 'can be included' do
      RSchema::DefaultDSL.include(MyCustomMethods)
      result = RSchema.dsl_eval{ modern_major_general }
      expect(result).to eq(:penzance)
    end
  end
end
