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

    def nodes
      # TODO: in '/v3/nodes' we must take 'name'
      api_nodes.map { |data| data['certname'] }
    end

    def nodes_update_facts_since(timestamp)
      ts = timestamp
      ts = Time.iso8601(ts) if ts.is_a?(String)
      json = api_nodes
      json.delete_if { |data| Time.iso8601(data["facts_timestamp"]) < ts }
      # TODO: in '/v3/nodes' we must take 'name'
      json.delete_if { |data| data["facts_timestamp"] }.map { |data| data['certname'] }
    end

    def node_facts(node)
      json = get_json("#{@nodes_url}/#{node}/facts", 10)
      return nil if json.include?("error")
      Hash[json.map { |data| [data["name"], data["value"]] }]
    end

    # get all facts
    def facts
      json = get_json(@facts_url, 60)
      # json.each { |fact| pp fact }
      result = {}
      json.each do |fact|
        data = result[fact["certname"]]
        result[fact["certname"]] = data = {} unless data
        data[fact["name"]] = fact["value"]
      end
      result
    end

    private

    def api_nodes
      get_json(@nodes_url, 10)
    end

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
