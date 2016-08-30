module PuppetDBQuery
  # access nodes and their facts from mongo database
  class MongoDB
    attr_reader :connection
    attr_reader :collection_name

    # @param connection  mongodb connection, should already be switched to correct database
    # @param collection  symbol for collection that contains nodes
    def initialize(connection, collection = :nodes)
      @connection = connection
      @collection_name = collection
    end

    # get node names that fulfill given mongodb query
    def query_nodes(query)
      collection = connection[collection_name]
      collection.find(query).batch_size(999).projection(_id: 1).map { |k| k[:_id] }
    end

    # get nodes and their facts that fulfill given mongodb query
    def query_facts(query, facts)
      fields = Hash[facts.collect { |fact| [fact.to_sym, 1] }]
      collection = connection[collection_name]
      result = {}
      collection.find(query).batch_size(999).projection(fields).each do |values|
        id = values.delete('_id')
        result[id] = values
      end
      result
    end

    # get all node names
    def nodes
      collection = connection[collection_name]
      collection.find.batch_size(999).projection(_id: 1).map { |k| k[:_id] }
    end

    # get facts for given node name
    def node_facts(node)
      collection = connection[collection_name]
      result = collection.find(_id: node).limit(999).batch_size(999).to_a.first
      result.delete("_id") if result
      result
    end

    # update or insert facts for given node name
    def node_update(node, facts)
      connection[collection_name].find(_id: node).replace_one(facts, upsert: true)
    rescue ::Mongo::Error::OperationFailure => e
      # mongodb doesn't support keys with a dot
      # see https://docs.mongodb.com/manual/reference/limits/#Restrictions-on-Field-Names
      # as a dirty workaround we delete the document and insert it ;-)
      # The dotted field .. in .. is not valid for storage. (57)
      raise e unless e.message =~ /The dotted field /
      connection[collection_name].find(_id: node).delete_one
      connection[collection_name].insert_one(facts.merge(_id: node))
    end

    # delete node data for given node name
    def node_delete(node)
      connection[collection_name].find(_id: node).delete_one
    end
  end
end
