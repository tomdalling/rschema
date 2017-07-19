# frozen_string_literal: true

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
  # Creates a schema object using a DSL
  #
  # @param dsl (see .dsl_eval)
  # @yield (see .dsl_eval)
  # @return [Schemas::Convenience] The schema object returned from the block,
  #   wrapped in a {Schemas::Convenience}.
  #
  # @example (see Schemas::FixedHash)
  #
  def self.define(dsl = nil, &block)
    schema = dsl_eval(dsl, &block)
    Schemas::Convenience.wrap(schema)
  end

  #
  # Runs a block using a DSL.
  #
  # @param dsl [Object] An optional DSL object to run the block with.
  #   Uses {RSchema#default_dsl} if nil.
  # @yield Invokes the given block with access to the methods on `dsl`.
  # @return The return value of the given block (usually some kind of schema
  #   object)
  #
  # @example Creating a typical fixed hash schema
  #   person_schema = RSchema.dsl_eval do
  #     fixed_hash(
  #       name: _String,
  #       age: _Integer,
  #     )
  #   end
  #
  def self.dsl_eval(dsl = nil, &block)
    if block.nil?
      raise ArgumentError, 'Must provide a block for the RSchema DSL'
    end

    Docile::Execution.exec_in_proxy_context(
      dsl || default_dsl,
      Docile::FallbackContextProxy,
      &block
    )
  end

  #
  # A convenience method for creating {Schemas::FixedHash} schemas
  #
  # This method is a shorter way to write:
  #
  #     RSchema.define do
  #       fixed_hash(...)
  #     end
  #
  # @yield (see .dsl_eval)
  # @yieldreturn The attributes of the hash schema
  #   (the argument to {DSL#fixed_hash}).
  # @return [Schemas::Convenience] A {Schemas::FixedHash} schema wrapped in a
  #   {Schemas::Convenience}.
  #
  # @example A typical fixed hash schema
  #     person_schema = RSchema.define_hash {{
  #       name: _String,
  #       age: _Integer,
  #     }}
  #
  def self.define_hash(&block)
    Schemas::Convenience.wrap(
      default_dsl.fixed_hash(dsl_eval(&block)),
    )
  end

  #
  # A convenience method for creating {Schemas::Predicate} schemas.
  #
  # This method is a shorter way to write:
  #
  #     RSchema.define do
  #       predicate(name) { ... }
  #     end
  #
  # @param name (see DSL#predicate)
  # @yield (see DSL#predicate)
  # @yieldreturn (see DSL#predicate)
  # @return [Schemas::Convenience] A {Schemas::Predicate} schema wrapped in a
  #   {Schemas::Convenience}.
  #
  # @example A predicate schema that only allows `odd?` objects.
  #     odd_schema = RSchema.define_predicate('odd') do |x|
  #       x.odd?
  #     end
  #
  # @see DSL#predicate
  #
  def self.define_predicate(name = nil, &block)
    Schemas::Convenience.wrap(
      default_dsl.predicate(name, &block),
    )
  end

  #
  # @return The default DSL object.
  # @see DefaultDSL
  #
  def self.default_dsl
    @default_dsl ||= DefaultDSL.new
  end

  #
  # The class of the default DSL object.
  #
  # By default, this only includes the methods from the {RSchema::DSL} mixin.
  #
  # Your own code and other gems may include modules into this class, in order
  # to add new methods to the default DSL.
  #
  class DefaultDSL
    include RSchema::DSL
  end

  #
  # Indicates that validation has failed
  #
  class Invalid < StandardError
    attr_reader :validation_error

    def initialize(validation_error)
      super()
      @validation_error = validation_error
    end
  end
end
