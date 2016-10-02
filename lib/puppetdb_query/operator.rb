require_relative "tokenizer"

module PuppetDBQuery
  # operator with priority and representation information
  class Operator
    attr_reader :symbol
    attr_reader :infix
    attr_reader :priority
    attr_reader :minimum
    attr_reader :maximum
    attr_reader :string

    def initialize(symbol, infix, priority, minimum, maximum = nil)
      @symbol = symbol
      @infix = infix
      @priority = priority
      @minimum = minimum
      @maximum = maximum
      @string = Tokenizer.symbol_to_string(symbol)
    end

    def infix?
      infix
    end

    def prefix?
      !infix
    end

    def ==(other)
      other.class == self.class && other.symbol == symbol
    end

    def to_s
      @string
    end
  end
end
