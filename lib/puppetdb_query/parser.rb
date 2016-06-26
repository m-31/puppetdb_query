require_relative "operator"
require_relative "term"
require_relative "tokenizer"

module PuppetDBQuery
  class Parser
    AND = Operator.new(:and, true, 100, 2)
    OR = Operator.new(:or, true, 90, 2)
    NOT = Operator.new(:not, false, 1, 1, 1)
    EQUAL = Operator.new(:equal, true, 200, 2, 2)
    NOT_EQUAL = Operator.new(:not_equal, true, 200, 2, 2)
    MATCH = Operator.new(:match, true, 200, 2, 2)

    OPERATORS = {
      AND.symbol   =>  AND,
      OR.symbol    =>  OR,
      NOT.symbol   =>  NOT,
      EQUAL.symbol =>  EQUAL,
      NOT_EQUAL.symbol =>  NOT_EQUAL,
      MATCH.symbol =>  MATCH,
    }

    attr_reader :position
    attr_reader :symbols

    def initialize(query)
      @symbols = Tokenizer.symbols(query)
      @position = 0
    end

    def read_expression
      r = []
      while !empty?
        r << read_maximal_term(0)
      end
      r
    end

    # Reads next maximal term. The following input doesn't make the term ore complete.
    # Respects the priority of operators by comparing it to the given value.
    def read_maximal_term(priority)
      return nil if empty?
      first = read_minimal_term
      add_next_infix_terms(priority, first)
    end

    # Read next following term. This is a complete term but some infix operator
    # or some terms for an infix operator might follow.
    def read_minimal_term
      term = nil
      operator = get_operator
      if operator
        error("'#{operator}' is no prefix operator") unless operator.prefix?
        read_token
        term = Term.new(operator)
        arg = read_maximal_term(operator.priority)
        term.add(arg)
        debug("read_minimal_term: #{term}")
        return term
      end
      # no prefix operator found
      token = get_token
      if token == :begin
        read_token
        term = read_maximal_term(0)
        error "'#{Tokenizer.symbol_to_string(:end)}' expected " unless read_token == :end
      elsif token == :list_begin
        read_token
        term = read_maximal_term(0)
        error "'#{Tokenizer.symbol_to_string(:list_end)}' expected " unless read_token == :list_end
      else
        error("no operator #{get_operator} expected here") if get_operator
        token = read_token
        debug("atom found: #{token}")
        term = token
      end
      return term
    end

    def add_next_infix_terms(priority, first)
      old_operator = nil
      term = first
      while true
        # we expect an infix operator
        operator = get_operator
        debug("we found operator '#{operator}'") if operator
        if operator.nil? || operator.prefix? || operator.priority <= priority
          debug("'#{operator}' is prefex '#{operator && operator.prefix?}' or has less priority #{operator && operator.priority} than #{priority}")
          debug("get_next_infix_terms: #{term}")
          return term
        end
        if old_operator.nil? || old_operator.priority >= operator.priority
          # old operator has not less priority
          read_token
          new_term = read_maximal_term(operator.priority)
          error("to few arguments for operator '#{operator}'") if new_term.nil?
          if old_operator == operator
            if operator.maximum && term.args.size + 1 >= operator.maximum
              raise "to much arguments for operator '#{operator}'"
            end
            term.add(new_term)
          else
            also_new_term = Term.new(operator)
            also_new_term.add(term)
            also_new_term.add(new_term)
            term = also_new_term
          end
        else
          # old operator has less priority
          new_term = read_maximal_term(operator.priority)
          error("to few arguments for operator '#{operator}'") if new_term.nil?
          also_new_term = Term.new(operator)
          also_new_term.add(term)
          also_new_term.add(new_term)
          term = also_new_term
        end
      end
    end

    def get_operator
      OPERATORS[get_token]
    end

    def read_token
      return nil if empty?
      token = symbols[position]
      @position += 1
      token
    end

    def empty?
      position >= symbols.size
    end

    def get_token
      return nil if empty?
      symbols[position]
    end

    def error(message)
      length = Tokenizer.query(symbols[0..position]).size
      raise "parsing query failed\n#{message}\n\n#{Tokenizer.query(symbols)}\n#{' ' * length}^"
    end

    def debug(*message)
      puts "    #{message}"
    end
  end
end


if $0 == __FILE__
  query = "facts=-7.4E1 and fucts=8 and fits=true or lhotse_vertical='ops' and (lhotse_group=\"live\"or lhotse_group='prelive-cluster')"
  puts query
  query = PuppetDBQuery::Tokenizer.idem(query)
  puts query
  query = PuppetDBQuery::Tokenizer.idem(query)
  puts query

  parser = PuppetDBQuery::Parser.new(query)
  tree = parser.read_expression
  pp tree
end

