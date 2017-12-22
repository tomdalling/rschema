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
