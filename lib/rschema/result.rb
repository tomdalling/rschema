module RSchema
  class Result
    def self.success(value = nil)
      if value.nil?
        NIL_SUCCESS
      else
        new(true, value, nil)
      end
    end

    def self.failure(error = nil)
      if error.nil?
        NIL_FAILURE
      else
        new(false, nil, error)
      end
    end

    def initialize(valid, value, error)
      @valid = valid
      @value = value
      @error = error
      freeze
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

    NIL_SUCCESS = new(true, nil, nil)
    NIL_FAILURE = new(false, nil, nil)
  end
end
