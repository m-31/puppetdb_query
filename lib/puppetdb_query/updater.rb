require_relative "logging"

module PuppetDBQuery
  # update nodes data from source to destination
  class Updater
    include Logging

    attr_reader :source
    attr_reader :destination

    def initialize(source, destination)
      @source = source
      @destination = destination
    end

    # update by deleting missing nodes and iterating over all nodes and
    # update or insert facts for each one
    #
    # 335.6 seconds: update time for 1561 nodes
    def update
      source_nodes = source.nodes
      destination_nodes = destination.nodes
      (destination_nodes - source_nodes).each do |node|
        destination.node_delete(node)
      end
      source_nodes.each do |node|
        begin
          destination.node_update(node, source.node_facts(node))
        rescue
          logging.error $!
        end
      end
    end

    # update by deleting missing nodes and get a complete map of nodes with facts
    # and update or insert facts for each one
    #
    # 166.4 seconds: update time for 1561 nodes
    def update2
      source_nodes = source.nodes
      destination_nodes = destination.nodes
      (destination_nodes - source_nodes).each do |node|
        destination.node_delete(node)
      end
      complete = source.facts
      complete.each do |node, facts|
        begin
          destination.node_update(node, facts)
        rescue
          logging.error $!
        end
      end
    end

    # update by deleting missing nodes and getting a list of nodes
    # with changed facts, iterate over them and update or insert facts for each one
    #
    # update time depends extremly on the number of changed nodes
    def update3(last_update_timestamp)
      source_nodes = source.nodes
      destination_nodes = destination.nodes
      (destination_nodes - source_nodes).each do |node|
        destination.node_delete(node)
      end
      modified = source.nodes_update_facts_since(last_update_timestamp)
      modified.each do |node|
        begin
          destination.node_update(node, source.node_facts(node))
        rescue
          logging.error $!
        end
      end
      modified.size
    end
  end
end
