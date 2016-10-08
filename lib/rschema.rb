require 'rschema/options'
require 'rschema/error'
require 'rschema/result'
require 'rschema/schemas/type'
require 'rschema/schemas/maybe'
require 'rschema/schemas/enum'
require 'rschema/schemas/boolean'
require 'rschema/schemas/sum'
require 'rschema/schemas/chain'
require 'rschema/schemas/anything'
require 'rschema/schemas/predicate'
require 'rschema/schemas/variable_hash'
require 'rschema/schemas/fixed_hash'
require 'rschema/schemas/variable_length_array'
require 'rschema/schemas/fixed_length_array'
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
