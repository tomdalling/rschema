class CoercerStub
  def initialize(&coerce_block)
    @coerce_block = coerce_block || ->(x){x}
  end

  def call(value)
    begin
      RSchema::Result.success(@coerce_block.call(value))
    rescue
      RSchema::Result.failure
    end
  end
end
