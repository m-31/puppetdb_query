require 'time'

require_relative "logging"

module PuppetDBQuery
  # access nodes and their facts from mongo database
  class MongoDB
    include Logging
    attr_reader :connection
    attr_reader :nodes_collection
    attr_reader :nodes_properties_collection
    attr_reader :meta_collection

    # initialize access to mongodb
    #
    # You might want to adjust the logging level, for example:
    #   ::Mongo::Logger.logger.level = logger.level
    #
    # @param connection        mongodb connection, should already be switched to correct database
    # @param nodes             symbol for collection that contains nodes with their facts
    # @param nodes_properties  symbol for collection for nodes with their update timestamps
    # @param meta              symbol for collection with update metadata
    def initialize(connection, nodes = :nodes, nodes_properties = :nodes_properties, meta = :meta)
      @connection = connection
      @nodes_collection = nodes
      @nodes_propeties_collection = nodes_properties
      @meta_collection = meta
    end

    # get node names that fulfill given mongodb query
    def query_nodes(query)
      collection = connection[nodes_collection]
      collection.find(query).batch_size(999).projection(_id: 1).map { |k| k[:_id] }
    end

    # get nodes and their facts that fulfill given mongodb query
    def query_facts(query, facts)
      fields = Hash[facts.collect { |fact| [fact.to_sym, 1] }]
      collection = connection[nodes_collection]
      result = {}
      collection.find(query).batch_size(999).projection(fields).each do |values|
        id = values.delete('_id')
        result[id] = values
      end
      result
    end

    # get all node names
    def nodes
      collection = connection[nodes_collection]
      collection.find.batch_size(999).projection(_id: 1).map { |k| k[:_id] }
    end

    # get facts for given node name
    def node_facts(node)
      collection = connection[nodes_collection]
      result = collection.find(_id: node).limit(999).batch_size(999).to_a.first
      result.delete("_id") if result
      result
    end

    # get all nodes and their facts
    def facts
      collection = connection[nodes_collection]
      result = {}
      collection.find.batch_size(999).each do |values|
        id = values.delete('_id')
        result[id] = values
      end
      result
    end

    # update or insert facts for given node name
    def node_update(node, facts)
      connection[nodes_collection].find(_id: node).replace_one(facts, upsert: true)
    rescue ::Mongo::Error::OperationFailure => e
      # mongodb doesn't support keys with a dot
      # see https://docs.mongodb.com/manual/reference/limits/#Restrictions-on-Field-Names
      # as a dirty workaround we delete the document and insert it ;-)
      # The dotted field .. in .. is not valid for storage. (57)
      raise e unless e.message =~ /The dotted field /
      connection[nodes_collection].find(_id: node).delete_one
      connection[nodes_collection].insert_one(facts.merge(_id: node))
    end

    # delete node data for given node name
    def node_delete(node)
      connection[nodes_collection].find(_id: node).delete_one
    end

    # update node properties
    def node_properties_update(new_node_properties, ts_begin)
      collection = connection[nodes_properties_collection]
      old_names = collection.find.batch_size(999).projection(_id: 1).map { |k| k[:_id] }
      delete = old_names - new_node_properties.keys
      collection.insert_many(nodes_properties.map { |k, v| v.dup.tap { v[:_id] = k } })
      collection.delete_many(_id: { '$in' => delete })
      ts_end = Time.iso8601(Time.now)
      connection[meta_collection].find_one_and_update(
        {},
        {
          '$set' => {
            last_node_properties_update: {
              ts_begin: ts_begin,
              ts_end:   ts_end
            }
          }
        },
        { upsert: true }
      )
    end

    # update or insert timestamps for given fact update method
    def meta_fact_update(method, ts_begin, ts_end)
      connection[meta_collection].find_one_and_update(
        {},
        {
          '$set' => {
            last_fact_update: {
              ts_begin: ts_begin,
              ts_end:   ts_end,
              method:   method
            },
            method => {
              ts_begin: ts_begin,
              ts_end:   ts_end
            }
          }
        },
        { upsert: true }
      )
    end
  end
end
