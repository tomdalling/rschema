require 'set'

RSpec.describe RSchema::Error do
  let(:error) {
    RSchema::Error.new(
      schema: schema,
      value: 'dog',
      symbolic_name: :not_a_duck,
      vars: { fee: 'fi fo' },
    )
  }
  let(:schema) { TestNamespace::TestSchema.new }

  specify '#to_s provides a short, developer-friendly description' do
    expect(error.to_s).to eq('TestNamespace::TestSchema/not_a_duck')
  end

  describe '#inspect' do
    it 'provides a detailed, developer-friendly description' do
      expect(error.inspect).to eq(
        '<RSchema::Error TestNamespace::TestSchema/not_a_duck fee="fi fo" value="dog">'
      )
    end

    it 'works without vars' do
      error.vars.clear
      expect(error.inspect).to eq(
        '<RSchema::Error TestNamespace::TestSchema/not_a_duck value="dog">'
      )
    end
  end

  module TestNamespace
    class TestSchema
    end
  end
end
