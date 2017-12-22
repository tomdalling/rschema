RSpec.describe RSchema::Schemas::Pipeline do
  subject { described_class.new([first_subschema, last_subschema]) }

  let(:first_subschema) do
    SchemaStub.new do |value|
      if String === value
        RSchema::Result.success(value + "3")
      else
        RSchema::Result.failure
      end
    end
  end

  let(:last_subschema) do |value|
    SchemaStub.new do |value|
      begin
        RSchema::Result.success(Integer(value))
      rescue
        RSchema::Result.failure
      end
    end
  end

  it_behaves_like 'a schema'

  it 'passes the result of each schema to the next schema' do
    result = validate('5')

    expect(result).to be_valid
    expect(result.value).to eq(53)
  end

  it 'gives an invalid result if _any_ subschema gives an invalid result' do
    expect(validate(:not_a_string)).to be_invalid
    expect(validate('not an integer')).to be_invalid
  end

  specify '#with_wrapped_subschemas' do
    wrapped = subject.with_wrapped_subschemas(WrapperStub)

    expect(wrapped).not_to be(subject)
    expect(wrapped.subschemas).to all(be_a WrapperStub)
    expect(wrapped.subschemas.map(&:wrapped_subschema)).to eq([first_subschema, last_subschema])
  end
end

class ChainSchemaStub
  def initialize(inputs_to_outputs)
    @inputs_to_outputs = inputs_to_outputs
  end

  def call(value, options)
    if @inputs_to_outputs.key?(value)
      RSchema::Result.success(@inputs_to_outputs.fetch(value))
    else
      RSchema::Result.failure(RSchema::Error.new(
        schema: self,
        value: value,
        symbolic_name: :unrecognised_input,
      ))
    end
  end

  def with_wrapped_subschemas(wrapper)
    wrapper.wrap(self)
  end
end
