require 'active_record'
require 'logger'

module BindLogAnalyzer
  module Connector

    def setup_db(database_params, setup_database = false, log_level = 0)
      @database_params = database_params
      
      self.connect

      migrate_tables if setup_database

      self.load_environment
      if log_level > 0
        
        log_level_class = {
          1 => Logger::WARN,
          2 => Logger::INFO,
          3 => Logger::DEBUG
        }

        log = Logger.new STDOUT
        log.level = log_level_class[log_level]
        ActiveRecord::Base.logger = log
      end
    end

    def migrate_tables
      ActiveRecord::Migration.verbose = true
      ActiveRecord::Migrator.migrate File.dirname(__FILE__) + '../../db/migrate'
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