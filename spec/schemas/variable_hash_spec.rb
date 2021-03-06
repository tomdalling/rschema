RSpec.describe RSchema::Schemas::VariableHash do
  subject { described_class.new(key_schema, value_schema) }
  let(:key_schema) { SchemaStub.new { |x| x.is_a?(Symbol) } }
  let(:value_schema) { SchemaStub.new }

  it_behaves_like 'a schema'

  context 'valid result' do
    it 'allows empty hashes' do
      result = validate({})
      expect(result).to be_valid
      expect(result.value).to eq({})
    end

    it 'allows hashes of arbirary size' do
      result = validate({ cat: :valid, dog: :valid })
      expect(result).to be_valid
      expect(result.value).to eq({ cat: :valid, dog: :valid })
    end
  end

  context 'invalid result' do
    specify 'due to not being a hash' do
      result = validate(5)

      expect(result.error).to have_attributes(
        schema: subject,
        value: 5,
        symbolic_name: :not_a_hash,
      )
    end

    specify 'due to invalid key' do
      result = validate({ 5 => :valid })

      expect(result.error).to eq({
        keys: { 5 => key_schema.error },
        values: {},
      })
    end

    it 'due to invalid value' do
      result = validate({ hello: :wrong })

      expect(result.error).to eq({
        keys: {},
        values: { hello: value_schema.error },
      })
    end

    it 'due to both invalid keys and invalid values' do
      result = validate({ hello: :wrong, 5 => :valid })

      expect(result.error).to eq({
        keys: { 5 => key_schema.error },
        values: { hello: value_schema.error },
      })
    end

    it 'respects the `fail_fast` option' do
      options = RSchema::Options.new(fail_fast: true)
      input = { hello: :wrong, 5 => :valid }

      result = validate(input, options)

      expect(result.error).to eq({
        keys: {}, # this would contain errors without the `fail_fast` option
        values: { hello: value_schema.error},
      })
    end
  end

  specify '#with_wrapped_subschemas' do
    wrapped = subject.with_wrapped_subschemas(WrapperStub)

    expect(wrapped.key_schema).to be_a(WrapperStub)
    expect(wrapped.key_schema.wrapped_subschema).to be(key_schema)
    expect(wrapped.value_schema).to be_a(WrapperStub)
    expect(wrapped.value_schema.wrapped_subschema).to be(value_schema)
  end
end
