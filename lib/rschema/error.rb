module RSchema
  class Error
    attr_reader :schema, :value, :symbolic_name, :vars

    def initialize(schema:, value:, symbolic_name:, vars: {})
      @schema = schema
      @value = value
      @symbolic_name = symbolic_name
      @vars = vars
      freeze
    end
  end
end
