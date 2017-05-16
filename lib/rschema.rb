require 'docile'

require 'rschema/options'
require 'rschema/error'
require 'rschema/result'
require 'rschema/schemas'
require 'rschema/dsl'
require 'rschema/coercers'
require 'rschema/coercion_wrapper'
require 'rschema/rack_param_coercer'

module RSchema
  def self.define(dsl = nil, &block)
    Docile::Execution.exec_in_proxy_context(
      dsl || default_dsl,
      Docile::FallbackContextProxy,
      &block
    )
  end

  def self.define_hash(&block)
    default_dsl.fixed_hash(define(&block))
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
