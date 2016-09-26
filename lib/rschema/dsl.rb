module RSchema
  module DSL
    def kind_of(type)
      Schemas::Type.new(type)
    end
    alias_method :_, :kind_of

    def array_of(element_subschema)
      Schemas::VariableLengthArray.new(element_subschema)
    end

    def method_missing(sym, *args, &block)
      type = sym.to_s
      if type.start_with?('_') && args.empty? && block.nil?
        klass = Object.const_get(type[1..-1])
        kind_of(klass)
      else
        super
      end
    end
  end
end
