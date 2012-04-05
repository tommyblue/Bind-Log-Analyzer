require 'bind_log_analyzer/exceptions'
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
      BindLogAnalyzer::Connector.setup_db_confs(database_params)

      BindLogAnalyzer::Connector.connect

      migrate_tables if setup_database

      self.load_environment

      BindLogAnalyzer::Connector.set_log_level(log_level)
    end

    # Launches ActiveRecord migrations
    def migrate_tables
      ActiveRecord::Migration.verbose = true
      migrations_dir = File.join(File.dirname(__FILE__), '..', '..', 'db/migrate')
      ActiveRecord::Migrator.migrate migrations_dir
    end

    # Establishes the connection to the database
    def self.connect
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

    # Setups the database params calling #setup_db_confs and log level calling #set_log_level then connects to the database
    # @param [Hash, String] database_params The path to the database configurations file or a hash containing such informations
    # @param [String] logfile The path to the file containing the Bind's logs to analyze
    def self.establish_connection(database_params, log_level)
      BindLogAnalyzer::Connector.setup_db_confs(database_params)  
      BindLogAnalyzer::Connector.connect
      BindLogAnalyzer::Connector.set_log_level(log_level)
    end

    # Analyzes the database_params param and extracts the database parameters. Raises BindLogAnalyzer::DatabaseConfsNotValid
    # if it can't find any useful information
    # @param [Hash, String] database_params The path to the database configurations file or a hash containing such informations
    def self.setup_db_confs(database_params)
      if database_params
        if database_params.instance_of?(Hash)
          @database_params = database_params
        else
          # Load the yaml file
          if FileTest.exists?(database_params)
            @database_params = YAML::load(File.open(database_params))['database']
          else
            raise BindLogAnalyzer::DatabaseConfsNotValid, "The indicated YAML file doesn't exist or is invalid"
          end
        end
      else
        # Tries to find the yaml file or prints an error
        filename = './database.yml'
        if FileTest.exists?(filename)
            @database_params = YAML::load(File.open(filename))['database']
        else
          raise BindLogAnalyzer::DatabaseConfsNotValid, "Can't find valid database configurations"
        end
      end
    end

    # Sets the log level
    # @param [String] logfile The path to the file containing the Bind's logs to analyze
    def self.set_log_level(log_level)
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
  end
end