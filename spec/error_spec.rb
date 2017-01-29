require 'set'

RSpec.describe RSchema::Error do
  let(:error) {
    RSchema::Error.new(
      schema: schema,
      value: 'dog',
      symbolic_name: :not_a_duck,
      vars: { fee: Set.new(['fie', 'foe']) },
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
      Vars: {:fee=>#<Set: {"fie", "foe"}>}
    EOS
  end

  it 'provides a json-compatible hash' do
    json = error.to_json

    expect(json[:schema]).to eq('TestNamespace::TestSchema')
    expect(json[:error]).to eq('not_a_duck')
    expect(json[:value]).to eq('dog')
    expect(json[:vars][:fee]).to start_with('#<Set:')
  end

  module TestNamespace
    class TestSchema
    end
  end
end
