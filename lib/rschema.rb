require 'docile'

require 'rschema/options'
require 'rschema/error'
require 'rschema/result'
require 'rschema/schemas'
require 'rschema/dsl'
require 'rschema/coercers'
require 'rschema/coercion_wrapper'

#
# Schema-based validation and coercion
#
module RSchema

  #
  # Runs a block using a DSL.
  #
  # @param dsl [Object] An optional DSL object to run the block with.
  #   Uses {RSchema#default_dsl} if nil.
  # @yield Invokes the given block with access to the methods on `dsl`.
  # @return The return value of the given block (usually some kind of schema object)
  #
  # @example Creating a typical fixed hash schema
  #   person_schema = RSchema.define do
  #     fixed_hash(
  #       name: _String,
  #       age: _Integer,
  #     )
  #   end
  #
  def self.define(dsl = nil, &block)
    Docile::Execution.exec_in_proxy_context(
      dsl || default_dsl,
      Docile::FallbackContextProxy,
      &block
    )
  end

  #
  # A shortcut for:
  #
  #     RSchema.define do
  #       fixed_hash(...)
  #     end
  #
  # @yield Invokes the given block with access to the methods of the default DSL.
  # @yieldreturn The attributes of the hash schema (the argument to {DSL#fixed_hash}).
  # @return [Schemas::FixedHash]
  #
  # @example A typical schema
  #
  #     person_schema = RSchema.define_hash {{
  #       name: _String,
  #       age: _Integer,
  #     }}
  #
  def self.define_hash(&block)
    default_dsl.fixed_hash(define(&block))
  end

  #
  # A shortcut for:
  #
  #     RSchema.define do
  #       predicate { ... }
  #     end
  #
  # @param name [String] An arbitraty name for the predicate schema.
  # @yields [value] Yields a single value.
  # @yieldreturn [Boolean] true if the value is valid, otherwise false.
  # @return [Schemas::Predicate]
  #
  # @example A predicate schema that only allows `odd?` objects.
  #
  #     odd_schema = RSchema.define_predicate('odd') do |x|
  #       x.odd?
  #     end
  #
  # @see DSL#predicate
  #
  def self.define_predicate(name = nil, &block)
    default_dsl.predicate(name, &block)
  end

  #
  # @return The default DSL object.
  # @see DefaultDSL
  #
  def self.default_dsl
    @default_dsl ||= DefaultDSL.new
  end

  #
  # The class of the default RSchema DSL.
  #
  # By default, this only includes the methods from the {RSchema::DSL} mixin.
  #
  # Your own code and other gems may include modules into this class, in order
  # to add new methods to the default DSL.
  #
  class DefaultDSL
    include RSchema::DSL
  end
end
