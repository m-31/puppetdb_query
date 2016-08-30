require 'net/http'
require 'json'

module PuppetDBQuery
  # access puppetdb data
  class PuppetDB
    NODES = "/v3/nodes".freeze
    FACTS = "/v3/facts".freeze

    def initialize(host = HOST, port = 443, protocol = "https", nodes = NODES, facts = FACTS)
      @nodes_url = "#{protocol}://#{host}:#{port}#{nodes}"
      @facts_url = "#{protocol}://#{host}:#{port}#{facts}"
      @lock = Mutex.new
    end

    def nodes
      @lock.synchronize do
        uri = URI.parse(@nodes_url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http.read_timeout = 10
        request = Net::HTTP::Get.new(uri.request_uri)
        request['Accept'] = "application/json"
        response = http.request(request)
        # TODO: in '/v4/nodes' we must take 'certname'
        JSON.parse(response.body).map { |data| data['name'] }
      end
    end

    def nodes_update_facts_since(timestamp)
      @lock.synchronize do
        ts = timestamp
        ts = Time.iso8601(ts) if ts.is_a?(String)
        uri = URI.parse(@nodes_url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http.read_timeout = 10
        request = Net::HTTP::Get.new(uri.request_uri)
        request['Accept'] = "application/json"
        response = http.request(request)
        json = JSON.parse(response.body)
        json.delete_if { |data| Time.iso8601(data["facts_timestamp"]) < ts }
        # TODO: in '/v4/nodes' we must take 'certname'
        json.delete_if { |data| data["facts_timestamp"] }.map { |data| data['name'] }
      end
    end

    def node_facts(node)
      @lock.synchronize do
        uri = URI.parse("#{@nodes_url}/#{node}/facts")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http.read_timeout = 10
        request = Net::HTTP::Get.new(uri.request_uri)
        request['Accept'] = "application/json"
        response = http.request(request)
        json = JSON.parse(response.body)
        return nil if json.include?("error")
        Hash[json.map { |data| [data["name"], data["value"]] }]
      end
    end

    # get all facts
    def facts
      @lock.synchronize do
        uri = URI.parse(@facts_url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http.read_timeout = 60
        request = Net::HTTP::Get.new(uri.request_uri)
        request['Accept'] = "application/json"
        response = http.request(request)
        json = JSON.parse(response.body)
        # json.each { |fact| pp fact }
        result = {}
        json.each do |fact|
          data = result[fact["certname"]]
          result[fact["certname"]] = data = {} unless data
          data[fact["name"]] = fact["value"]
        end
        result
      end
    end
  end
end
