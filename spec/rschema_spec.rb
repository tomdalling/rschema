RSpec.describe RSchema do
  it 'provides schema-based validation' do
    schema = RSchema.define{ _Integer }

    valid_result = schema.call(5)
    expect(valid_result).to be_valid

    invalid_result = schema.call('hello')
    expect(invalid_result).not_to be_valid
  end

  it 'provides error details' do
    schema = RSchema.define { array_of(_Symbol) }

    result = schema.call([:a, :b, 'see'])
    expect(result).not_to be_valid
    expect(result.error).to be_a(Hash)
    expect(result.error).to have_key(2)

    error = result.error[2]
    expect(error).to be_a(RSchema::Error)
    expect(error.schema).to be_a(RSchema::Schemas::Type)
    expect(error.value).to eq('see')
    expect(error.symbolic_name).to eq('rschema/type/invalid')
  end

  it 'provides coercion' do
    schema = RSchema.define { array_of(_Symbol) }
    coercer = RSchema::HTTPCoercer.wrap(schema)

    result = coercer.call(['a', :b, 'c'])

    expect(result).to be_valid
    expect(result.value).to eq([:a, :b, :c])
  end
end
