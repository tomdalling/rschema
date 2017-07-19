# frozen_string_literal: true

module RSchema
  #
  # Settings, passed in as an argument when calling schemas
  #
  class Options
    def self.default
      @default ||= new
    end

    def self.fail_fast
      @fail_fast ||= new(fail_fast: true)
    end

    def initialize(fail_fast: false)
      @fail_fast = fail_fast
    end

    def fail_fast?
      @fail_fast
    end
  end
end
