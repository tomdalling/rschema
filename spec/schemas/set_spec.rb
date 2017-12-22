RSpec.describe RSchema::Schemas::Set do
  subject { described_class.new(subschema) }
  let(:subschema) { SchemaStub.that_succeeds_where { |value| Symbol === value } }

  it_behaves_like 'a schema'

  context 'valid result' do
    it 'allows empty sets' do
      result = validate(Set.new)
      expect(result).to be_valid
      expect(result.value).to eq(Set.new)
    end

    it 'allows sets of arbirary size' do
      input = Set.new([:a, :b, :c])

      result = validate(input)

      expect(result).to be_valid
      expect(result.value).to eq(Set.new([:a, :b, :c]))
    end
  end

  context 'invalid result' do
    specify 'due to not being a set' do
      result = validate(5)

      expect(result).not_to be_valid
      expect(result.error).to have_attributes(
        schema: subject,
        value: 5,
        symbolic_name: :not_a_set,
      )
    end

    specify 'due to invalid subschema' do
      input = Set.new([5])

      result = validate(input)

      expect(result).not_to be_valid
      expect(result.error).to eq({
        5 => subschema.errors.last,
      })
    end

    it 'respects the `fail_fast` option' do
      options = RSchema::Options.new(fail_fast: true)
      input = Set.new([:valid, 2, 3])

      result = validate(input, options)

      expect(result).not_to be_valid
      expect(result.error.size).to eq(1)
    end
  end

  specify '#with_wrapped_subschemas' do
    wrapped = subject.with_wrapped_subschemas(WrapperStub)

    expect(wrapped.subschema).to be_a(WrapperStub)
    expect(wrapped.subschema.wrapped_subschema).to be(subschema)
  end
end
