module RSchema
  class Options
    def self.default
      @default ||= new
    end

    def initialize(fail_fast: false)
      @fail_fast = fail_fast
    end

    def fail_fast?
      @fail_fast
    end
  end
end
