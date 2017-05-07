module RSchema
module Coercers

  module Boolean
    extend self

    TRUTHY_STRINGS = ['on', '1', 'true', 'yes']
    FALSEY_STRINGS = ['off', '0', 'false', 'no']

    def build(schema)
      self
    end

    def call(value)
      case value
      when true, false then Result.success(value)
      when nil then Result.success(false)
      when String
        case
        when TRUTHY_STRINGS.include?(value.downcase) then Result.success(true)
        when FALSEY_STRINGS.include?(value.downcase) then Result.success(false)
        else Result.failure
        end
      else Result.failure
      end
    end
  end

end
end
