require_relative "parser"
require_relative "logging"

module PuppetDBQuery
  # convert puppetdb query into mongodb query
  class ToMongo
    include Logging

    def query(string)
      logger.info "transfer following string into mongo query:"
      logger.info(string)
      terms = Parser.parse(string)
      mongo_query = query_term(terms[0])
      logger.info "resulting mongo query:"
      logger.info mongo_query.inspect
      mongo_query
    end

    private

    # rubocop:disable Metrics/PerceivedComplexity
    def query_term(term)
      # rubocop:disable Style/GuardClause
      if term.is_a?(Symbol)
        return term.to_s
      elsif term.is_a?(Integer)
        return "'#{term}'"
      elsif term.is_a?(TrueClass)
        return term.to_s
      elsif !term.is_a?(Term)
        return "'#{term}'"
      end
      # rubocop:enable Style/GuardClause
      terms = term.args.map { |t| query_term(t) }
      case term.operator.symbol
      when :and
        { :$and => terms }
      when :or
        { :$or => terms }
      when :equal
        { term.args[0] => term.args[1].to_s }
      when :not_equal
        { term.args[0] => { :$ne => term.args[1].to_s } }
      when :match
        { term.args[0] => { :$regex => term.args[1].to_s } }
      else
        raise "can't handle operator '#{term.operator}' yet"
      end
    end
    # rubocop:enable Metrics/PerceivedComplexity
  end
end
