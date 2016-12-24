RSpec.describe RSchema::Error do
  let(:error) {
    RSchema::Error.new(
      schema: schema,
      value: 'dog',
      symbolic_name: :not_a_duck,
      vars: { fee: 'fie foe' },
    )
  }
  let(:schema) { TestNamespace::TestSchema.new }

  it 'provides a short, developer-friendly description' do
    expect(error.to_s).to eq(
      'Error TestNamespace::TestSchema/not_a_duck for value: "dog"'
    )
  end

  it 'provides a long, developer-friendly description' do
    expect(error.to_s(:detailed)).to eq(<<~EOS)
      Error: not_a_duck
      Schema: TestNamespace::TestSchema
      Value: "dog"
      Vars: {:fee=>"fie foe"}
    EOS
  end

  it 'provides a json-compatible hash' do
    expect(error.to_json).to eq({
      schema: 'TestNamespace::TestSchema',
      error: 'not_a_duck',
      value: 'dog',
      vars: { fee: 'fie foe' }
    })
  end

  module TestNamespace
    class TestSchema
    end
  end
end
