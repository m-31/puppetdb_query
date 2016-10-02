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

    def ==(other)
      other.class == self.class && other.operator == operator && other.args == args
    end

    def to_s
      if operator.prefix?
        "#{operator}(#{args.join(', ')})"
      elsif operator.infix?
        "(#{args.join(" #{operator} ")})"
      else
        raise "unkown representation for operator: #{operator}"
      end
    end
  end
end
