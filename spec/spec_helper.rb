require 'simplecov'
SimpleCov.start

RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.disable_monkey_patching!
  config.warnings = true
  config.order = :random

  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end

  Kernel.srand config.seed
end

require 'rschema'
require 'pry'
require 'schema_stub'
require 'wrapper_stub'

RSpec.shared_examples 'a schema' do
  it 'responds to #call' do
    expect(subject).to respond_to(:call)
    expect(subject.method(:call).arity).to eq(-2)
  end

  it 'responds to #with_wrapped_subschemas' do
    expect(subject).to respond_to(:with_wrapped_subschemas)
    expect(subject.method(:with_wrapped_subschemas).arity).to eq(1)
  end
end

