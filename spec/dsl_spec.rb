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

  describe '#array' do
    specify 'variable-length' do
      subschema = double

      schema = subject.array(subschema)

      expect(schema).to be_a(RSchema::Schemas::VariableLengthArray)
      expect(schema.element_schema).to be(subschema)
    end

    specify 'fixed-length' do
      first_subschema = double
      last_subschema = double

      schema = subject.array(first_subschema, last_subschema)

      expect(schema).to be_a(RSchema::Schemas::FixedLengthArray)
      expect(schema.subschemas).to eq([first_subschema, last_subschema])
    end
  end

  specify '#boolean' do
    schema = subject.boolean()

    expect(schema).to be(RSchema::Schemas::Boolean.instance)
  end

  specify '#set' do
    subschema = double

    schema = subject.set(subschema)

    expect(schema).to be_a(RSchema::Schemas::Set)
    expect(schema.subschema).to be(subschema)
  end

  specify '#fixed_hash' do
    attr1 = double
    attr2 = double
    expect(subject).to receive(:attributes).with(555).and_return([attr1, attr2])

    schema = subject.fixed_hash(555)

    expect(schema).to be_a(RSchema::Schemas::FixedHash)
    expect(schema.attributes).to eq([attr1, attr2])
  end

  specify '#attributes' do
    name_schema = double
    age_schema = double

    attrs = subject.instance_eval do
      attributes(
        name: name_schema,
        optional(:age) => age_schema,
      )
    end

    expect(attrs.first).to have_attributes(
      key: :name,
      value_schema: name_schema,
      optional: false,
    )
    expect(attrs.last).to have_attributes(
      key: :age,
      value_schema: age_schema,
      optional: true,
    )
  end

  describe '#variable_hash' do
    specify 'correct usage' do
      key_schema = double
      value_schema = double

      schema = subject.variable_hash(key_schema => value_schema)

      expect(schema).to be_a(RSchema::Schemas::VariableHash)
      expect(schema.key_schema).to be(key_schema)
      expect(schema.value_schema).to be(value_schema)
    end

    specify 'incorrect usage' do
      expect {
        subject.variable_hash(a: 1, b: 2)
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
