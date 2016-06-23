require 'pp'

module PuppetDBQuery
  class MongoQuery
    attr_reader :connection

    def initialize(hosts, options)
      @connection = Mongo::Client.new(hosts, options)
    end

    def nodes(query)
      puts "starting query"
      collection = @connection[:nodes]
      puts "found: #{collection.find(query).count}"
      result = []
      cursor = collection.find(query, fields: ['_id'])
      cursor.each do |document|
        result << document[:_id]
      end
      pp result
      result
    end

    def facts(query, facts)
      puts "starting query"
      pp query
      #fields = facts << ':_id'
      #pp "fields: #{fields}"
      collection = @connection[:nodes]
      puts "found: #{collection.find(query).count}"
      result = {}
      # cursor = collection.find(query, {:fields => ["os"]}).to_a
      cursor = collection.find(query, :fields => facts)
      cursor.each do |document|
        values = {}
        facts.each { |fact| values[fact] = document[fact] }
        result[document['_id']] = values
      end
      pp result
      result
    end
  end
end