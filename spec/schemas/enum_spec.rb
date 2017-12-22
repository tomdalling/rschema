RSpec.describe RSchema::Schemas::Enum do
  subject { described_class.new([:a, :b, :c], subschema) }
  let(:subschema) do
    SchemaStub.that_succeeds_where { |value| Symbol === value }
  end

  it_behaves_like 'a schema'

  specify 'successful validation' do
    result = validate(:b)

    expect(result).to be_valid
    expect(result.value).to eq(:b)
  end

  describe 'failed validation' do
    specify 'due to not being an enum member' do
      result = validate(:z)

      expect(result).not_to be_valid
      expect(result.error).to have_attributes(
        schema: subject,
        value: :z,
        symbolic_name: :not_a_member,
      )
    end

    specify 'due to subschema failure' do
      result = validate('waka')

      expect(result).not_to be_valid
      expect(result.error).to be(subschema.errors.last)
    end
  end

  specify '#with_wrapped_subschemas' do
    wrapped = subject.with_wrapped_subschemas(WrapperStub)
    expect(wrapped).to be_a(described_class)
    expect(wrapped).not_to be(subject)
    expect(wrapped.subschema).to be_a(WrapperStub)
    expect(wrapped.subschema.wrapped_subschema).to be(subschema)
  end
end
