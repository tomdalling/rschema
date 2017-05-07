require 'rschema/options'
require 'rschema/error'
require 'rschema/result'
require 'rschema/schemas'
require 'rschema/dsl'
require 'rschema/coercers'
require 'rschema/coercion_wrapper'
require 'rschema/rack_param_coercer'

module RSchema
  def self.define(&block)
    default_dsl.instance_eval(&block)
  end

  def self.define_hash(&block)
    default_dsl.Hash(define(&block))
  end

  def self.define_predicate(name = nil, &block)
    default_dsl.predicate(name, &block)
  end

  def self.default_dsl
    @default_dsl ||= DefaultDSL.new
  end

  class DefaultDSL
    include RSchema::DSL
  end
end
