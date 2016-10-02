require_relative 'logging'
require_relative 'updater'

module PuppetDBQuery
  # sync node and fact data from source to destination
  class Sync
    include Logging

    attr_reader :source
    attr_reader :destination

    def initialize(source, destination)
      @source = source
      @destination = destination
    end

    def sync(minutes = 5, seconds = 10)
      logger.info "syncing puppetdb nodes and facts started"
      Timeout::timeout(60 * minutes - seconds) do
        updater = PuppetDBQuery::Updater.new(source, destination)


        updater.update_node_properties

        # make a full update
        timestamp = Time.now
        updater.update2

        # make delta updates til our time is up
        while true
          begin
            ts = Time.now
            updater.update3(timestamp - 2)
            timestamp = ts
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
  end
end
