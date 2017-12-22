RSpec.describe SchemaStub do
  subject { described_class.that_always_succeeds }

  it_behaves_like 'a schema'

  it 'can be wrapped' do
    stub = SchemaStub.new
    wrapped = stub.with_wrapped_subschemas(WrapperStub)
    expect(wrapped).to be(stub)
  end
end
