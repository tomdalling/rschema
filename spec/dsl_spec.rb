RSpec.describe RSchema::DSL do
  subject { TestDSL.new }
  class TestDSL; include RSchema::DSL; end

  describe '#type' do
    specify 'explicit usage' do
      schema = subject.type(Integer)

      expect(schema).to be_a(RSchema::Schemas::Type)
      expect(schema.type).to be(Integer)
    end

    describe 'underscore shorthand' do
      specify 'existing class' do
        schema = subject._Integer

        expect(schema).to be_a(RSchema::Schemas::Type)
        expect(schema.type).to be(Integer)
      end

      specify 'non-existant class' do
        expect {
          subject._WakaWaka
        }.to raise_error(NameError, 'uninitialized constant WakaWaka')
      end

      specify 'without underscore' do
        expect {
          subject.waka_waka
        }.to raise_error(NoMethodError, /undefined method `waka_waka'/)
      end
    end
  end

  describe '#Array' do
    specify 'variable-length' do
      subschema = double

      schema = subject.Array(subschema)

      expect(schema).to be_a(RSchema::Schemas::VariableLengthArray)
      expect(schema.element_schema).to be(subschema)
    end

    specify 'fixed-length' do
      first_subschema = double
      last_subschema = double

      schema = subject.Array(first_subschema, last_subschema)

      expect(schema).to be_a(RSchema::Schemas::FixedLengthArray)
      expect(schema.subschemas).to eq([first_subschema, last_subschema])
    end
  end

  specify '#Boolean' do
    schema = subject.Boolean()

    expect(schema).to be(RSchema::Schemas::Boolean.instance)
  end

  specify '#Set' do
    subschema = double

    schema = subject.Set(subschema)

    expect(schema).to be_a(RSchema::Schemas::Set)
    expect(schema.subschema).to be(subschema)
  end

  specify '#Hash' do
    name_schema = double
    age_schema = double

    schema = subject.instance_eval do
      Hash(name: name_schema, optional(:age) => age_schema)
    end

    expect(schema).to be_a(RSchema::Schemas::FixedHash)
    expect(schema.attributes.first).to have_attributes(
      key: :name,
      value_schema: name_schema,
      optional: false,
    )
    expect(schema.attributes.last).to have_attributes(
      key: :age,
      value_schema: age_schema,
      optional: true,
    )
  end

  specify '#Hash(based_on: x)' do
    username_schema = double
    password_schema = double
    token_schema = double
    original_schema = subject.instance_eval do
      Hash(username: username_schema, password: password_schema)
    end

    merged_schema = subject.Hash_based_on(original_schema, {
      password: nil, # remove :password attribute
      token: token_schema, # add a new :token attribute
    })

    expect(merged_schema).to be_a(RSchema::Schemas::FixedHash)
    expect(merged_schema.attributes.size).to eq(2)
    expect(merged_schema.attributes.first).to have_attributes(
      key: :username,
      value_schema: username_schema,
    )
    expect(merged_schema.attributes.last).to have_attributes(
      key: :token,
      value_schema: token_schema,
    )
  end

  describe '#VariableHash' do
    specify 'correct usage' do
      key_schema = double
      value_schema = double

      schema = subject.VariableHash(key_schema => value_schema)

      expect(schema).to be_a(RSchema::Schemas::VariableHash)
      expect(schema.key_schema).to be(key_schema)
      expect(schema.value_schema).to be(value_schema)
    end

    specify 'incorrect usage' do
      expect {
        subject.VariableHash(a: 1, b: 2)
      }.to raise_error(ArgumentError, 'argument must be a Hash of size 1')
    end
  end

  specify '#maybe' do
    subschema = double

    schema = subject.maybe(subschema)

    expect(schema).to be_a(RSchema::Schemas::Maybe)
    expect(schema.subschema).to be(subschema)
  end

  specify '#enum' do
    subschema = subject._Integer
    schema = subject.enum([1, 2, 3], subschema)

    expect(schema).to be_a(RSchema::Schemas::Enum)
    expect(schema.members).to contain_exactly(1, 2, 3)
    expect(schema.subschema).to be(subschema)
  end

  specify '#either' do
    alternate1 = double
    alternate2 = double

    schema = subject.either(alternate1, alternate2)

    expect(schema).to be_a(RSchema::Schemas::Sum)
    expect(schema.subschemas).to eq([alternate1, alternate2])
  end

  specify '#predicate' do
    callable = ->(x){ x }

    schema = subject.predicate('hello', &callable)

    expect(schema).to be_a(RSchema::Schemas::Predicate)
    expect(schema.block).to be(callable)
    expect(schema.name).to eq('hello')
  end

  specify '#pipeline' do
    subschema1 = double
    subschema2 = double

    schema = subject.pipeline(subschema1, subschema2)

    expect(schema).to be_a(RSchema::Schemas::Pipeline)
    expect(schema.subschemas).to eq([subschema1, subschema2])
  end

  specify '#anything' do
    expect(subject.anything).to be(RSchema::Schemas::Anything.instance)
  end
end
