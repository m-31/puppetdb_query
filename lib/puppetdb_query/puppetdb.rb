require 'net/http'
require 'json'

require_relative 'logging'

module PuppetDBQuery
  # access puppetdb data
  class PuppetDB
    include Logging

    NODES = "/v4/nodes".freeze
    FACTS = "/v4/facts".freeze

    def initialize(host = HOST, port = 443, protocol = "https", nodes = NODES, facts = FACTS)
      @nodes_url = "#{protocol}://#{host}:#{port}#{nodes}"
      @facts_url = "#{protocol}://#{host}:#{port}#{facts}"
      @lock = Mutex.new
    end

    # get array of node names
    def nodes
      # TODO: perhaps we have to ignore entries without "deactivated": null?
      # TODO: in '/v3/nodes' we must take 'name'
      api_nodes.map { |data| data['certname'] }
    end

    # get array of node names
    def nodes_properties
      result = {}
      api_nodes.each do |data|
        next if data['deactivated']
        # TODO: in '/v3/nodes' we must take 'name'
        name = data['certname']
        values = data.dup
        %w(deactivated certname).each { |key| values.delete(key) }
        result[name] = values
      end
      result
    end

    # get all nodes that have updated facts
    def nodes_update_facts_since(timestamp)
      ts = (timestamp.is_a?(String) ? Time.iso8601(ts) : timestamp)
      nodes_properties.delete_if do |_k, data|
        # TODO: in '/v3/nodes' we must take 'facts_timestamp'
        !data["facts-timestamp"] || Time.iso8601(data["facts-timestamp"]) < ts
      end.keys
    end

    # get hash of facts for given node name
    def node_facts(node)
      json = get_json("#{@nodes_url}/#{node}/facts", 10)
      return nil if json.include?("error")
      Hash[json.map { |data| [data["name"], data["value"]] }]
    end

    # get all nodes with all facts
    def facts
      json = get_json(@facts_url, 60)
      result = {}
      json.each do |fact|
        data = result[fact["certname"]]
        result[fact["certname"]] = data = {} unless data
        data[fact["name"]] = fact["value"]
      end
      result
    end

    def api_nodes
      get_json(@nodes_url, 10)
    end

    private

    def get_json(url, timeout)
      @lock.synchronize do
        logger.info "get json from #{url}"
        uri = URI.parse(url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http.read_timeout = timeout
        request = Net::HTTP::Get.new(uri.request_uri)
        request['Accept'] = "application/json"
        response = http.request(request)
        logger.info "  got #{response.body.size} characters from #{url}"
        JSON.parse(response.body)
      end
    end
  end
end
