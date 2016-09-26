require 'rschema/options'
require 'rschema/error'
require 'rschema/result'
require 'rschema/schemas/type'
require 'rschema/schemas/variable_length_array'
require 'rschema/dsl'
require 'rschema/http_coercer'

module RSchema
  def self.define(&block)
    @dsl ||= DefaultDSL.new
    @dsl.instance_eval(&block)
  end

  class DefaultDSL
    include RSchema::DSL
  end
end
