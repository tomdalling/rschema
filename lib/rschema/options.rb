module RSchema
  class Options
    def self.default
      @default ||= new
    end

    def initialize(vars={})
      @fail_fast = vars.fetch(:fail_fast, false)
    end

    def fail_fast?
      @fail_fast
    end
  end
end
