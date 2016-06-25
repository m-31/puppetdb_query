require_relative "parser"

module PuppetDBQuery
  # convert puppetdb query into mongodb query
  class ToMongo
    def query(string)
      parser = Parser.new(string)
      terms = parser.read_expression()
      return query_term(terms[0])
    end

    private

    def query_term(term)
      if term.is_a?(Symbol)
        return term.to_s
      elsif !term.is_a?(Term)
        return term
      end
      terms = term.args.map { |t| query_term(t) }
      case term.operator.symbol
      when :and
        { :$and => terms }
      when :or
        { :$or => terms }
      when :equal
        { term.args[0] => term.args[1] }
      when :not_equal
        { term.args[0] => { :$ne => query_term(term.args[1]) } }
      else
        raise "can't handle operator '#{term.operator}' yet"
      end
    end
  end
end
