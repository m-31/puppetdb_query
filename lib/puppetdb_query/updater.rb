module PuppetDBQuery
  # update nodes data from source to destination
  class Updater
    attr_reader :source
    attr_reader :destination

    def initialize(source, destination)
      @source = source
      @destination = destination
    end

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
          STDERR.puts $!
        end
      end
    end
  end
end
