require 'active_record'
require 'logger'

module BindLogAnalyzer
  module Connector

    def setup_db(database_params, enable_logs = true)
      @database_params = database_params
      self.connect
      self.load_environment
      if enable_logs
        log = Logger.new STDOUT
        log.level = Logger::WARN
        ActiveRecord::Base.logger = log
      end
    end

    def connect
      ActiveRecord::Base.establish_connection(@database_params)
    end

    def connected?
      ActiveRecord::Base.connected?
    end

    def load_environment
      Dir.glob('./lib/models/*').each { |r| require r }
    end
  end
end