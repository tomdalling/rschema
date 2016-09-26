module RSchema
  class Error
    attr_reader :schema, :value, :symbolic_name

    def initialize(schema:, value:, symbolic_name:)
      @schema = schema
      @value = value
      @symbolic_name = symbolic_name
      freeze
    end
  end
end
