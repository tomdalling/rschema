require 'rschema/options'
require 'rschema/error'
require 'rschema/result'
require 'rschema/schemas/type'
require 'rschema/schemas/maybe'
require 'rschema/schemas/enum'
require 'rschema/schemas/boolean'
require 'rschema/schemas/sum'
require 'rschema/schemas/pipeline'
require 'rschema/schemas/anything'
require 'rschema/schemas/predicate'
require 'rschema/schemas/set'
require 'rschema/schemas/variable_hash'
require 'rschema/schemas/fixed_hash'
require 'rschema/schemas/variable_length_array'
require 'rschema/schemas/fixed_length_array'
require 'rschema/dsl'
require 'rschema/http_coercer'

module RSchema
  def self.define(&block)
    default_dsl.instance_eval(&block)
  end

  def self.define_hash(&block)
    default_dsl.Hash(define(&block))
  end

  def self.default_dsl
    @default_dsl ||= DefaultDSL.new
  end

  class DefaultDSL
    include RSchema::DSL
  end
end
