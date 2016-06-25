module PuppetDBQuery
  # update nodes data from source to destination
  class Updater
    attr_reader :source
    attr_reader :destination

    def initialize(source, destination)
      @source = source
      @destination = destination
    end

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
          STDERR.puts $!  # TODO logger
        end
      end
    end

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
          STDERR.puts $!
        end
      end
    end

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
          STDERR.puts $!  # TODO logger
        end
      end
      modified.size
    end
  end
end
