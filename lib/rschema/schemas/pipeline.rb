module RSchema
module Schemas
class Pipeline
  attr_reader :subschemas

  def initialize(subschemas)
    @subschemas = subschemas
  end

  def call(value, options)
    result = Result.success(value)

    subschemas.each do |subsch|
      result = subsch.call(result.value, options)
      break if result.invalid?
    end

    result
  end

  def with_wrapped_subschemas(wrapper)
    wrapped_subschemas = subschemas.map{ |ss| wrapper.wrap(ss) }
    self.class.new(wrapped_subschemas)
  end

end
end
end
