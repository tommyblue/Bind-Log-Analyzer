require 'active_record'
require 'logger'

module BindLogAnalyzer
  # The module which provides connection facility
  module Connector

    # Main connection method which connects to the database, launches migrations if requested,
    # loads the Log ActiveRecord model and setups the logger.
    # @param [Hash] database_params The database params and credentials
    # @param [true, false] setup_database If true launches the migrations of the database
    # @param [Integer] log_level The log level to setup the Logger
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

    # Launches ActiveRecord migrations
    def migrate_tables
      ActiveRecord::Migration.verbose = true
      migrations_dir = File.join(File.dirname(__FILE__), '..', '..', 'db/migrate')
      ActiveRecord::Migrator.migrate migrations_dir
    end

    # Establishes the connection to the database
    def connect
      ActiveRecord::Base.establish_connection(@database_params)
    end

    # Shows the status of the connection to the database
    # @return [true, false] The status of the connection to the database
    def connected?
      ActiveRecord::Base.connected?
    end

    # Loads the ActiveRecord models
    def load_environment
      Dir.glob('./lib/models/*').each { |r| require r }
    end
  end
end