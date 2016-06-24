require 'pp'

module PuppetDBQuery
  class MongoQuery
    attr_reader :connection

    def initialize(hosts, options)
      @connection = Mongo::Client.new(hosts, options)
    end

    def nodes(query)
      collection = @connection[:nodes]
      collection.find(query).limit(999).batch_size(999).projection(_id: 1).map { |k| k[:_id] }
    end

    def facts(query, facts)
      fields = Hash[facts.collect { |fact| [fact.to_sym, 1] }]
      collection = @connection[:nodes]
      result = {}
      collection.find(query).limit(999).batch_size(999).projection(fields).each do |values|
        id = values.delete('_id')
        result[id] = values
      end
      result
    end
  end
end