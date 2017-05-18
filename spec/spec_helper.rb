require 'simplecov'
Bundler.require
SimpleCov.start

begin; require 'byebug'; rescue LoadError; end

module SpecHelperMethods
  def validate(value, options=RSchema::Options.default)
    subject.call(value, options)
  end
end

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
  config.default_formatter = 'doc' if config.files_to_run.one?

  config.include SpecHelperMethods

  Kernel.srand config.seed

  # auto-require supporting classes/stuff
  Dir[__dir__ + '/support/**/*.rb'].each{ |path| require path }
end

require 'rschema'

RSpec.shared_examples 'a schema' do
  it 'responds to #call' do
    expect(subject).to respond_to(:call)
    expect(subject.method(:call).arity).to eq(2)
  end

  it 'responds to #with_wrapped_subschemas' do
    expect(subject).to respond_to(:with_wrapped_subschemas)
    expect(subject.method(:with_wrapped_subschemas).arity).to eq(1)
  end
end

