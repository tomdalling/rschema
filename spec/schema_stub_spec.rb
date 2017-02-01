RSpec.describe SchemaStub do
  it_behaves_like 'a schema'

  it 'can be wrapped' do
    stub = SchemaStub.new
    wrapped = stub.with_wrapped_subschemas(WrapperStub)
    expect(wrapped).to be(stub)
  end
end
