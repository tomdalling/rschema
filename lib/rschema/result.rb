# frozen_string_literal: true

module RSchema
  #
  # The return value when calling a schema
  #
  class Result
    def self.success(value = nil)
      if nil == value
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
      !valid?
    end

    def value
      raise RSchema::Invalid.new(error) if invalid?
      @value
    end

    attr_reader :error

    # @!visibility private
    NIL_SUCCESS = new(true, nil, nil)
    # @!visibility private
    NIL_FAILURE = new(false, nil, nil)
  end
end
