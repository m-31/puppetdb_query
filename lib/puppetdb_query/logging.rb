require 'logger'

module PuppetDBQuery
  # for logger access just include this module
  module Logging
    class << self
      attr_writer :logger

      def logger
        unless @logger
          @logger = Logger.new($stdout)
          @logger.level = (ENV['LOG_LEVEL'] || Logger::DEBUG).to_i
        end
        @logger
      end
    end

    # addition
    def self.included(base)
      class << base
        def logger
          # :nocov:
          Logging.logger
          # :nocov:
        end

        def logger=(logger)
          # :nocov:
          Logging.logger = logger
          # :nocov:
        end
      end
    end

    def logger
      Logging.logger
    end

    def logger=(logger)
      Logging.logger = logger
    end
  end
end
