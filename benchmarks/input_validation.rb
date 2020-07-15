require 'benchmark/ips'
require 'active_model'
require 'action_controller'
require 'dry-schema'
require 'dry/schema/version'

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

DRY_SCHEMA_PARAMS = Dry::Schema.Params do
  required(:name).value(:string)
  required(:age).maybe(:int?)
  optional(:password) { str? }
end

DRY_SCHEMA_JSON = Dry::Schema.JSON do
  required(:name).value(:string)
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
    #fail("Unexpected validation result") unless yield(input)
    yield(input)
  end
  BAD_INPUTS.each do |input|
    #fail("Unexpected validation result") if yield(input)
    yield(input)
  end
end

def title(str)
  str.rjust(25)
end

Benchmark.ips do |x|
  x.report(title("RSchema (#{RSchema::VERSION})")) do
    validate_inputs { |input| RSCHEMA.validate(input).valid? }
  end

  x.report(title('RSchema, coerced')) do
    validate_inputs { |input| COERCED_RSCHEMA.validate(input).valid? }
  end

  x.report(title('RSchema, built, coerced')) do
    validate_inputs do |input|
      schema = RSchema::CoercionWrapper::RACK_PARAMS.wrap(build_rschema)
      schema.validate(input).valid?
    end
  end

  x.report(title("ActiveModel #{ActiveModel::VERSION::STRING}")) do
    validate_inputs { |input| ActivePerson.new(input).valid? }
  end

  x.report(title("Strong Params")) do
    validate_inputs do |input|
      ActionController::Parameters.new(input)
        .permit(:name, :age, :password)
    end
  end

  x.report(title("dry-schema, Params, #{Dry::Schema::VERSION}")) do
    validate_inputs { |input| DRY_SCHEMA_PARAMS.call(input).success? }
  end

  x.report(title("dry-schema, JSON, #{Dry::Schema::VERSION}")) do
    validate_inputs { |input| DRY_SCHEMA_JSON.call(input).success? }
  end

  x.compare!
end
