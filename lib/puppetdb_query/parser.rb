require_relative "operator"
require_relative "term"
require_relative "tokenizer"
require_relative "logging"

module PuppetDBQuery
  # parse a puppetdb query string into #PuppetDBQuery::Term s
  # rubocop:disable Metrics/ClassLength
  class Parser
    include Logging

    def self.parse(puppetdb_query)
      Parser.new.parse(puppetdb_query)
    end

    # these are the operators we understand
    # rubocop:disable Style/ExtraSpacing
    AND       = Operator.new(:_and,       true,  100, 2)
    OR        = Operator.new(:_or,        true,   90, 2)
    NOT       = Operator.new(:_not,       false, 150, 1, 1)
    EQUAL     = Operator.new(:_equal,     true,  200, 2, 2)
    NOT_EQUAL = Operator.new(:_not_equal, true,  200, 2, 2)
    MATCH     = Operator.new(:_match,     true,  200, 2, 2)
    IN        = Operator.new(:_in,        true,  200, 2, 2)
    # rubocop:enable Style/ExtraSpacing

    # map certain symbols (we get them from a tokenizer) to our operators
    OPERATORS = {
      AND.symbol       =>  AND,
      OR.symbol        =>  OR,
      NOT.symbol       =>  NOT,
      EQUAL.symbol     =>  EQUAL,
      NOT_EQUAL.symbol =>  NOT_EQUAL,
      MATCH.symbol     =>  MATCH,
      IN.symbol        =>  IN,
    }.freeze

    attr_reader :symbols  # array of symbols
    attr_reader :position # current parsing position in array of symbols

    # parse query and get resulting array of PuppetDBQuery::Term s
    def parse(query)
      @symbols = Tokenizer.symbols(query)
      @position = 0
      r = []
      r << read_maximal_term(0) until empty?
      r
    end

    private

    # Reads next maximal term. The following input doesn't make the term more complete.
    # Respects the priority of operators by comparing it to the given value.
    def read_maximal_term(priority)
      return nil if empty?
      logger.debug "read maximal term (#{priority})"
      first = read_minimal_term
      term = add_next_infix_terms(priority, first)
      logger.debug "read maximal term: #{term}"
      term
    end

    # Read next following term. This is a complete term but some infix operator
    # or some terms for an infix operator might follow.
    # rubocop:disable Metrics/PerceivedComplexity,Metrics/AbcSize,Metrics/CyclomaticComplexity
    # rubocop:disable Metrics/MethodLength
    def read_minimal_term
      logger.debug "read minimal term"
      term = nil
      operator = get_operator
      if operator
        error("'#{operator}' is no prefix operator") unless operator.prefix?
        read_token
        term = Term.new(operator)
        if operator.maximum > 1
          error("'#{operator}' is prefix operator with more than one argument," \
                " that is not supported yet")
        end
        if operator.minimum > 0
          arg = read_maximal_term(operator.priority)
          error("prefix operator '#{operator}' got no argument") if arg.nil?
          term.add(arg)
        end
        logger.debug "read_minimal_term: #{term}"
        return term
      end
      # no prefix operator found
      token = get_token
      if token == :_begin
        logger.debug "read ()"
        read_token
        term = read_maximal_term(0)
        error "'#{Tokenizer.symbol_to_string(:_end)}' expected " unless get_token == :_end
        read_token
      elsif token == :_list_begin
        logger.debug "read []"
        read_token
        args = []
        loop do
          term = read_maximal_term(0)
          if get_token != :_list_end && get_token != :_comma
            error "'#{Tokenizer.symbol_to_string(:_list_end)}' or" \
                  " '#{Tokenizer.symbol_to_string(:_comma)}' expected"
          end
          args << term if term
          break if read_token == :_list_end
        end
        term = args
      else
        error("no operator #{get_operator} expected here") if get_operator
        if Tokenizer::LANGUAGE_STRINGS.include?(token) && ![:true, :false].include?(token)
          error("that was not expected here: '#{Tokenizer.symbol_to_string(token)}'")
        end
        token = read_token
        logger.debug "atom found: #{token}"
        term = token
      end
      logger.debug "read minimal term: #{term}"
      term
    end
    # rubocop:enable Metrics/PerceivedComplexity,Metrics/AbcSize,Metrics/CyclomaticComplexity
    # rubocop:enable Metrics/MethodLength

    # rubocop:disable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/BlockLength
    # rubocop:disable Metrics/MethodLength,Metrics/PerceivedComplexity
    def add_next_infix_terms(priority, first)
      old_operator = nil
      term = first
      loop do
        # we expect an infix operator
        operator = get_operator
        logger.debug "we found operator '#{operator}'" unless operator.nil?
        if operator.nil? || operator.prefix? || operator.priority <= priority
          logger.debug "operator '#{operator}' is nil" if operator.nil?
          logger.debug "operator '#{operator}' is prefex" if !operator.nil? && operator.prefix?
          if !operator.nil? && operator.priority <= priority
            logger.debug "operator '#{operator}' has less priority #{operator.priority}" \
                         " than #{priority}"
          end
          logger.debug "get_next_infix_terms: #{term}"
          return term
        end
        if old_operator.nil? || old_operator.priority >= operator.priority
          # old operator has not less priority
          read_token
          new_term = read_maximal_term(operator.priority)
          error("to few arguments for operator '#{operator}'") if new_term.nil?
          logger.debug "is '#{old_operator}' == '#{operator}' : #{old_operator == operator}"
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
        old_operator = operator
      end
    end
    # rubocop:enable Metrics/AbcSize,Metrics/CyclomaticComplexity,Metrics/BlockLength
    # rubocop:enable Metrics/MethodLength,Metrics/PerceivedComplexity

    # rubocop:disable Style/AccessorMethodName
    def get_operator
      OPERATORS[get_token]
    end
    # rubocop:enable Style/AccessorMethodName

    def read_token
      return nil if empty?
      token = symbols[position]
      @position += 1
      token
    end

    def empty?
      position >= symbols.size
    end

    # rubocop:disable Style/AccessorMethodName
    def get_token
      return nil if empty?
      symbols[position]
    end
    # rubocop:enable Style/AccessorMethodName

    def error(message)
      length = (position > 0 ? Tokenizer.query(symbols[0..(position - 1)]).size + 1 : 0)
      raise "parsing query failed\n#{message}\n\n#{Tokenizer.query(symbols)}\n#{' ' * length}^"
    end
  end
  # rubocop:enable Metrics/ClassLength
end

if $0 == __FILE__
  require "pp"
  query = "facts=-7.4E1 and fucts=8 and fits=true or application_vertical='ops' and" \
          " (application_group=\"live\"or application_group='prelive-production')"
  puts query
  query = PuppetDBQuery::Tokenizer.idem(query)
  puts query
  query = PuppetDBQuery::Tokenizer.idem(query)
  puts query

  parser = PuppetDBQuery::Parser.new
  tree = parser.parse(query)
  pp tree
end
