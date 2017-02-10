require_relative 'logging'
require_relative 'updater'

module PuppetDBQuery
  # sync node and fact data from source to destination
  class Sync
    include Logging

    attr_reader :source
    attr_reader :destination
    attr_reader :updater

    def initialize(source, destination)
      @source = source
      @destination = destination
    end

    def sync(minutes = 60, seconds = 10, seconds_back = 4)
      logger.info "syncing puppetdb nodes and facts started, running #{minutes} minutes"
      Timeout.timeout(60 * minutes - seconds) do
        @updater = PuppetDBQuery::Updater.new(source, destination)

        # make a full update
        timestamp = Time.now
        updater.update2

        # make delta updates til our time is up
        loop do
          begin
            check_minutely
            ts = Time.now
            updater.update3(timestamp - seconds_back)
            timestamp = ts
          rescue Timeout::Error
            logger.info "syncing puppetdb nodes: now our time is up, we finsh"
            return
          rescue
            logger.error $!
          end
          logger.info "sleep for #{seconds} seconds"
          sleep(seconds)
        end
      end
      logger.info "syncing puppetdb nodes and facts ended"
    rescue Timeout::Error
      logger.info "syncing puppetdb nodes: now our time is up, we finsh"
    rescue
      logger.error $!
    end

    # this method is called once in a minute at maximum
    # you may override this method to update you metrics...
    # @param ts Time from last node_properties update
    # @param node_number Integer number of nodes
    def minutely(ts, node_number)
      logger.info "node_properties update #{node_number} nodes" \
        " at timestamp: #{(ts.nil? ? '' : ts.iso8601)}"
    end

    private

    def check_minutely
      @last_minute ||= Time.now - 60
      timestamp = Time.now
      return if timestamp - 60 < @last_minute
      minutely(destination.node_properties_update_timestamp,
        updater.source_node_properties.size)
      @last_minute = timestamp
    rescue
      logger.error $!
    end
  end
end
