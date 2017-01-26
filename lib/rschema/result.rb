module RSchema
  class Result
    def self.success(value)
      new(true, value, nil)
    end

    def self.failure(error)
      new(false, nil, error)
    end

    def initialize(valid, value, error)
      @valid = valid
      @value = value
      @error = error
    end

    def valid?
      @valid
    end

    def invalid?
      not valid?
    end

    def value
      if valid?
        @value
      else
        raise InvalidError
      end
    end

    def error
      @error
    end

    class InvalidError < StandardError; end
  end
end
