RSpec.describe RSchema::Schemas::Predicate do
  subject do
    described_class.new(:even?.to_proc, 'bongos')
  end

  it_behaves_like 'a schema'

  it 'gives a valid result if the predicate passes' do
    expect(validate(4)).to be_valid
  end

  it 'gives an invalid result if the predicate fails' do
    result = validate(5)

    expect(result).not_to be_valid
    expect(result.error).to have_attributes(
      schema: subject,
      value: 5,
      symbolic_name: :false,
    )
  end

  it 'has a name' do
    expect(subject.name).to eq('bongos')
  end

  specify '#with_wrapped_subschemas' do
    wrapped = subject.with_wrapped_subschemas(WrapperStub)
    expect(wrapped).to be(subject)
  end
end
