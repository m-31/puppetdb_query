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

    def sync(minutes = 60, seconds = 10)
      logger.info "syncing puppetdb nodes and facts started, running #{minutes} minutes"
      Timeout.timeout(60 * minutes - seconds) do
        updater = PuppetDBQuery::Updater.new(source, destination)

        # make a full update
        timestamp = Time.now
        updater.update2

        # make delta updates til our time is up
        loop do
          begin
            check_minutely
            ts = Time.now
            updater.update3(timestamp - 2)
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

    # this method is called
    def minutely
      logger.info "node_properties update timestamp:" \
                  " #{destination.node_properties_update_timestamp}"
    end

    private

    def check_minutely
      @last_minute ||= Time.now - 60
      timestamp = Time.now
      return if timestamp - 60 < @last_minute
      minutely
      @last_minute = timestamp
    end
  end
end
