module PuppetDBQuery
  class Term
    attr_reader :operator
    attr_reader :args

    def initialize(operator)
      @operator = operator
      @args = []
    end

    def add(*arg)
      @args += arg
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
