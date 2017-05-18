RSpec.describe RSchema::Schemas::FixedHash do
  subject { described_class.new([name_attr, age_attr]) }
  let(:name_attr) { described_class::Attribute.new(:name, name_schema, false) }
  let(:name_schema) { SchemaStub.new{ |value| value.is_a?(String) } }
  let(:age_attr) { described_class::Attribute.new(:age, age_schema, true) }
  let(:age_schema) { SchemaStub.new{ |value| value.is_a?(Integer) && value.positive? } }

  it_behaves_like 'a schema'

  context 'successful validation' do
    specify 'with optional attrs present' do
      result = validate(name: 'Tom', age: 7)
      expect(result).to be_valid
      expect(result.value).to eq({ name: 'Tom', age: 7 })
    end

    specify 'with optional attrs missing' do
      result = validate(name: 'Tom')
      expect(result).to be_valid
      expect(result.value).to eq({ name: 'Tom' })
    end
  end

  context 'failed validation' do
    specify 'due to not being a hash' do
      result = validate(5)

      expect(result).not_to be_valid
      expect(result.error).to have_attributes(
        schema: subject,
        value: 5,
        symbolic_name: :not_a_hash,
      )
    end

    specify 'due to subschema failure' do
      result = validate(name: 123)

      expect(result).not_to be_valid
      expect(result.error).to have_key(:name)
      expect(result.error[:name]).to be(name_schema.error)
    end

    specify 'due to missing keys' do
      result = validate({})

      expect(result).not_to be_valid
      expect(result.error).to have_attributes(
        schema: subject,
        value: {},
        symbolic_name: :missing_attributes,
        vars: {
          missing_keys: [:name],
        },
      )
    end

    specify 'due to extraneous keys' do
      result = validate(name: 'Tom', unspecified_key: 123)

      expect(result).not_to be_valid
      expect(result.error).to have_attributes(
        schema: subject,
        value: { name: 'Tom', unspecified_key: 123 },
        symbolic_name: :extraneous_attributes,
        vars: {
          extraneous_keys: [:unspecified_key],
        },
      )
    end

    it 'respects the `fail_fast` option' do
      options = RSchema::Options.new(fail_fast: true)
      input = { name: 123, age: 'wawawa' }

      result = validate(input, options)

      expect(result).not_to be_valid
      expect(result.error.keys).to eq([:name])
    end
  end

  specify '#with_wrapped_subschemas' do
    wrapped = subject.with_wrapped_subschemas(WrapperStub)
    name_attr = wrapped.attributes.find{ |attr| attr.key == :name }

    expect(wrapped.attributes.map(&:value_schema)).to all(be_a WrapperStub)
    expect(name_attr.value_schema.wrapped_subschema).to be(name_schema)
  end

  it 'returns attribute objects via the subscript operator' do
    expect(subject[:name]).to be(name_attr)
  end

  describe '#merge' do
    it 'adds new attributes' do
      newattr = RSchema::Schemas::FixedHash::Attribute.new(:newattr, nil, true)
      merged = subject.merge([newattr])
      expect(merged.attributes).to match_array(subject.attributes + [newattr])
    end

    it 'overwrites existing attributes' do
      new_name_attr = RSchema::Schemas::FixedHash::Attribute.new(:name, nil, false)
      merged = subject.merge([new_name_attr])
      expect(merged.attributes).to match_array([age_attr, new_name_attr])
    end
  end

  describe '#without' do
    it 'removes attributes' do
      removed = subject.without([:name])
      expect(removed.attributes).to eq([age_attr])
    end
  end
end

