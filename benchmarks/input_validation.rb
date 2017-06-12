require 'benchmark/ips'
require 'active_model'
require 'dry-validation'

require_relative '../sh/env'
require 'rschema/coercion_wrapper/rack_params'

GOOD_INPUTS = [
  { name: 'Tom', age: 904 },
  { name: 'Piotr', age: nil },
  { name: 'Dane', age: 44, password: 'wigwam' },
]

BAD_INPUTS = [
  { name: nil, age: nil }, # nil not allowed for name
  { name: 'Tom', age: 'hello' }, # string not allowed for age
  { }, # all keys missing
]

def build_rschema
  RSchema.define_hash {{
    name: _String,
    age: maybe(_Integer),
    optional(:password) => _String,
  }}
end

RSCHEMA = build_rschema

DRY_SCHEMA = Dry::Validation.Schema do
  required(:name) { str? }
  required(:age).maybe(:int?)
  optional(:password) { str? }
end

COERCED_RSCHEMA = RSchema::CoercionWrapper::RACK_PARAMS.wrap(RSCHEMA)

class ActivePerson
  include ActiveModel::Model

  attr_accessor :name, :age, :password

  validates_presence_of :name
  validates_numericality_of :age, only_integer: true, allow_nil: true
end

def validate_inputs
  GOOD_INPUTS.each do |input|
    fail("Unexpected validation result") unless yield(input)
  end
  BAD_INPUTS.each do |input|
    fail("Unexpected validation result") if yield(input)
  end
end

Benchmark.ips do |x|
  x.report("RSchema #{RSchema::VERSION}") do
    validate_inputs { |input| RSCHEMA.validate(input).valid? }
  end

  x.report('(coerced)') do
    validate_inputs { |input| COERCED_RSCHEMA.validate(input).valid? }
  end

  x.report('(built + coerced)') do
    validate_inputs do |input|
      schema = RSchema::CoercionWrapper::RACK_PARAMS.wrap(build_rschema)
      schema.validate(input).valid?
    end
  end

  x.report("ActiveModel #{ActiveModel::VERSION::STRING}") do
    validate_inputs { |input| ActivePerson.new(input).valid? }
  end

  x.report("dry-validation #{Dry::Validation::VERSION}") do
    validate_inputs { |input| DRY_SCHEMA.call(input).success? }
  end

  x.compare!
end
