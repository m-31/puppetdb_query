require 'net/http'
require 'json'

module PuppetDBQuery
  class PuppetDB
    NODES = "/v4/nodes"

    def initialize(host = HOST, port = 443, protocol = "https", nodes = NODES)
      @url = "#{protocol}://#{host}:#{port}#{nodes}"
      @lock = Mutex.new
    end

    def nodes
      @lock.synchronize do
        uri = URI.parse(@url)
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http.read_timeout = 10
        request = Net::HTTP::Get.new(uri.request_uri)
        request['Accept'] = "application/json"
        response = http.request(request)
        JSON.parse(response.body).map { |data| data['certname'] }
      end
    end

    def facts(node)
      @lock.synchronize do
        uri = URI.parse("#{@url}/#{node}/facts")
        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = uri.scheme == 'https'
        http.read_timeout = 10
        request = Net::HTTP::Get.new(uri.request_uri)
        request['Accept'] = "application/json"
        response = http.request(request)
        Hash[JSON.parse(response.body).map { |data| [data["name"], data["value"]] }]
      end
    end
  end
end
