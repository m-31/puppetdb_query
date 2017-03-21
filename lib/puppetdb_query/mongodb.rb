require 'time'

require_relative "logging"

module PuppetDBQuery
  # access nodes and their facts from mongo database
  # rubocop:disable Metrics/ClassLength
  class MongoDB
    include Logging
    attr_reader :connection
    attr_reader :nodes_collection
    attr_reader :node_properties_collection
    attr_reader :meta_collection
    attr_reader :node_properties_update_timestamp

    # initialize access to mongodb
    #
    # You might want to adjust the logging level, for example:
    #   ::Mongo::Logger.logger.level = logger.level
    #
    # @param connection        mongodb connection, should already be switched to correct database
    # @param nodes             symbol for collection that contains nodes with their facts
    # @param node_properties   symbol for collection for nodes with their update timestamps
    # @param meta              symbol for collection with update metadata
    def initialize(connection, nodes = :nodes, node_properties = :node_properties, meta = :meta)
      @connection = connection
      @nodes_collection = nodes
      @node_properties_collection = node_properties
      @meta_collection = meta
    end

    # get all nodes and their update dates
    def node_properties
      collection = connection[node_properties_collection]
      result = {}
      collection.find.batch_size(999).each do |values|
        id = values.delete('_id')
        result[id] = values
      end
      result
    end

    # get all node names
    def all_nodes
      collection = connection[nodes_collection]
      collection.find.batch_size(999).projection(_id: 1).map { |k| k[:_id] }
    end

    # get node names that fulfill given mongodb query
    #
    # @param query mongodb query
    def query_nodes(query)
      collection = connection[nodes_collection]
      collection.find(query).batch_size(999).projection(_id: 1).map { |k| k[:_id] }
    end

    # get nodes and their facts that fulfill given mongodb query
    #
    # @param query mongodb query
    # @param facts [Array<String>] get these facts in the result, eg ['fqdn'], empty for all
    def query_facts(query, facts = [])
      fields = Hash[facts.collect { |fact| [fact.to_sym, 1] }]
      collection = connection[nodes_collection]
      result = {}
      collection.find(query).batch_size(999).projection(fields).each do |values|
        id = values.delete('_id')
        result[id] = values
      end
      result
    end

    # get nodes and their facts that fulfill given mongodb query and have at least one
    # value for one the given fact names
    #
    # @param query mongodb query
    # @param facts [Array<String>] get these facts in the result, eg ['fqdn'], empty for all
    def query_facts_exist(query, facts = [])
      result = query_facts(query, facts)
      unless facts.empty?
        result.keep_if do |_k, v|
          facts.any? { |f| !v[f].nil? }
        end
      end
      result
    end

    # get nodes and their facts for a pattern
    #
    # @param query mongodb query
    # @param pattern [RegExp] search for
    # @param facts [Array<String>] get these facts in the result, eg ['fqdn'], empty for all
    # @param facts_found [Array<String>] fact names are added to this array
    # @param check_names [Boolean] also search fact names
    def search_facts(query, pattern, facts = [], facts_found = [], check_names = false)
      collection = connection[nodes_collection]
      result = {}
      collection.find(query).batch_size(999).each do |values|
        id = values.delete('_id')
        found = {}
        values.each do |k, v|
          if v =~ pattern
            found[k] = v
          elsif check_names && k =~ pattern
            found[k] = v
          end
        end
        next if found.empty?
        facts_found.concat(found.keys).uniq!
        facts.each do |f|
          found[f] = values[f]
        end
        result[id] = found
      end
      result
    end

    # get facts for given node name
    #
    # @param node [String] node name
    # @param facts [Array<String>] get these facts in the result, eg ['fqdn'], empty for all
    def single_node_facts(node, facts)
      fields = Hash[facts.collect { |fact| [fact.to_sym, 1] }]
      collection = connection[nodes_collection]
      result = collection.find(_id: node).limit(1).batch_size(1).projection(fields).to_a.first
      result.delete("_id") if result
      result
    end

    # get all nodes and their facts
    #
    # @param facts [Array<String>] get these facts in the result, eg ['fqdn'], empty for all
    def facts(facts = [])
      fields = Hash[facts.collect { |fact| [fact.to_sym, 1] }]
      collection = connection[nodes_collection]
      result = {}
      collection.find.batch_size(999).projection(fields).each do |values|
        id = values.delete('_id')
        result[id] = values
      end
      result
    end

    # get meta informations about updates
    def meta
      collection = connection[meta_collection]
      result = collection.find.first
      result.delete(:_id)
      result
    end

    # update or insert facts for given node name
    #
    # @param node [String] node name
    # @param facts [Array<String>] get these facts in the result, eg ['fqdn'], empty for all
    def node_update(node, facts)
      connection[nodes_collection].find(_id: node).replace_one(facts, upsert: true, bypass_document_validation: false,  check_keys: false)
    rescue ::Mongo::Error::OperationFailure => e
      # mongodb doesn't support keys with a dot
      # see https://docs.mongodb.com/manual/reference/limits/#Restrictions-on-Field-Names
      # as a dirty workaround we delete the document and insert it ;-)
      # The dotted field .. in .. is not valid for storage. (57)
      raise e unless e.message =~ /The dotted field /
      connection[nodes_collection].find(_id: node).delete_one
      connection[nodes_collection].insert_one(facts.merge(_id: node), check_keys: false)
    end

    # delete node data for given node name
    #
    # @param node [String] node name
    def node_delete(node)
      connection[nodes_collection].find(_id: node).delete_one
    end

    # update node properties
    def node_properties_update(new_node_properties)
      collection = connection[node_properties_collection]
      old_names = collection.find.batch_size(999).projection(_id: 1).map { |k| k[:_id] }
      delete = old_names - new_node_properties.keys
      data = new_node_properties.map do |k, v|
        {
          replace_one:
          {
            filter: { _id: k },
            replacement: v,
            upsert: true
          }
        }
      end
      collection.bulk_write(data)
      collection.delete_many(_id: { '$in' => delete })
    end

    # update or insert timestamps for given fact update method
    def meta_fact_update(method, ts_begin, ts_end)
      connection[meta_collection].find_one_and_update(
        {},
        {
          '$set' => {
            last_fact_update: {
              ts_begin: ts_begin.iso8601,
              ts_end:   ts_end.iso8601,
              method:   method
            },
            method => {
              ts_begin: ts_begin.iso8601,
              ts_end:   ts_end.iso8601
            }
          }
        },
        { upsert: true }
      )
    end

    # update or insert timestamps for node_properties_update
    def meta_node_properties_update(ts_begin, ts_end)
      connection[meta_collection].find_one_and_update(
        {},
        {
          '$set' => {
            last_node_properties_update: {
              ts_begin: ts_begin.iso8601,
              ts_end:   ts_end.iso8601
            }
          }
        },
        { upsert: true }
      )
      @node_properties_update_timestamp = ts_begin
    end
  end
  # rubocop:enable Metrics/ClassLength
end
