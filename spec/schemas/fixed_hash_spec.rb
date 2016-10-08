RSpec.describe RSchema::Schemas::FixedHash do
  subject { described_class.new([name_attr, age_attr]) }
  let(:name_attr) { described_class::Attribute.new(:name, name_schema, false) }
  let(:name_schema) { MockSchema.new{ |value| value.is_a?(String) } }
  let(:age_attr) { described_class::Attribute.new(:age, age_schema, true) }
  let(:age_schema) { MockSchema.new{ |value| value.is_a?(Integer) && value.positive? } }

  context 'successful validation' do
    specify 'with optional attrs present' do
      result = subject.call(name: 'Tom', age: 7)
      expect(result).to be_valid
      expect(result.value).to eq({ name: 'Tom', age: 7 })
    end

    specify 'with optional attrs missing' do
      result = subject.call(name: 'Tom')
      expect(result).to be_valid
      expect(result.value).to eq({ name: 'Tom' })
    end
  end

  context 'failed validation' do
    specify 'due to not being a hash' do
      result = subject.call(5)

      expect(result).not_to be_valid
      expect(result.error).to have_attributes(
        schema: subject,
        value: 5,
        symbolic_name: 'rschema/fixed_hash/not_a_hash',
      )
    end

    specify 'due to subschema failure' do
      result = subject.call(name: 123)

      expect(result).not_to be_valid
      expect(result.error).to have_key(:name)
      expect(result.error[:name]).to be(name_schema.error)
    end

    specify 'due to missing keys' do
      result = subject.call({})

      expect(result).not_to be_valid
      expect(result.error).to have_attributes(
        schema: subject,
        value: {},
        symbolic_name: 'rschema/fixed_hash/missing_attributes',
        vars: [:name],
      )
    end

    specify 'due to extraneous keys' do
      result = subject.call(name: 'Tom', unspecified_key: 123)

      expect(result).not_to be_valid
      expect(result.error).to have_attributes(
        schema: subject,
        value: { name: 'Tom', unspecified_key: 123 },
        symbolic_name: 'rschema/fixed_hash/extraneous_attributes',
        vars: [:unspecified_key],
      )
    end

    it 'respects the `fail_fast` option' do
      options = RSchema::Options.new(fail_fast: true)
      input = { name: 123, age: 'wawawa' }

      result = subject.call(input, options)

      expect(result).not_to be_valid
      expect(result.error.keys).to eq([:name])
    end
  end

  specify '#with_wrapped_subschemas' do
    wrapped = subject.with_wrapped_subschemas(MockWrapper)
    name_attr = wrapped.attributes.find{ |attr| attr.key == :name }

    expect(wrapped.attributes.map(&:value_schema)).to all(be_a MockWrapper)
    expect(name_attr.value_schema.wrapped_subschema).to be(name_schema)
  end
end

