# frozen_string_literal: true

module RSchema
  #
  # Contains info about how a schema failed validation
  #
  class Error
    attr_reader :schema, :value, :symbolic_name, :vars

    def initialize(schema:, value:, symbolic_name:, vars: {})
      raise ArgumentError.new('vars must be a hash') unless vars.is_a?(Hash)

      @schema = schema
      @value = value
      @symbolic_name = symbolic_name
      @vars = vars

      freeze
    end

    def to_s
      "#{schema.class}/#{symbolic_name}"
    end

    def inspect
      attrs = vars.merge(value: value)
                  .map { |k, v| "#{k}=#{v.inspect}" }
                  .join(' ')

      "<#{self.class} #{self} #{attrs}>"
    end
  end
end
