module PuppetDBQuery
  # represent a term containing an operator and arguments
  class Term
    attr_reader :operator
    attr_reader :args

    def initialize(operator)
      @operator = operator
      @args = []
    end

    def add(*arg)
      @args += arg
      self
    end

    def ==(o)
      o.class == self.class && o.operator == operator && o.args == args
    end

    def to_s
      if operator.prefix?
        "#{operator}(#{args.join(", ")})"
      elsif operator.infix?
        "(#{args.join(" #{operator} ")})"
      else
        raise "unkown representation for operator: #{operator}"
      end
    end
  end
end
