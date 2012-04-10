require 'bind_log_analyzer/exceptions'
require 'active_record'

module BindLogAnalyzer
  # The module which provides connection facility
  module Connector

    # Main connection method which connects to the database, launches migrations if requested,
    # loads the Log ActiveRecord model and setups the logger.
    # @param [Hash] database_params The database params and credentials
    # @param [true, false] setup_database If true launches the migrations of the database
    def setup_db(database_params, setup_database = false)
      BindLogAnalyzer::Connector.setup_db_confs(database_params, @log)

      BindLogAnalyzer::Connector.connect

      migrate_tables if setup_database

      self.load_environment

      ActiveRecord::Base.logger = @log
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
      Dir.glob('./lib/models/*').each do |r|
        @log.debug "Requiring model #{r}"
        require r
      end
    end

    # Setups the database params calling #setup_db_confs and log level calling #set_log_level then connects to the database
    # @param [Hash, String] database_params The path to the database configurations file or a hash containing such informations
    # @param [String] logfile The path to the file containing the Bind's logs to analyze
    def self.establish_connection(database_params, logger)
      BindLogAnalyzer::Connector.setup_db_confs(database_params, logger)  
      BindLogAnalyzer::Connector.connect
      ActiveRecord::Base.logger = logger
    end

    # Analyzes the database_params param and extracts the database parameters. Raises BindLogAnalyzer::DatabaseConfsNotValid
    # if it can't find any useful information
    # @param [Hash, String] database_params The path to the database configurations file or a hash containing such informations
    def self.setup_db_confs(database_params, logger)
      if database_params
        if database_params.instance_of?(Hash)
          logger.debug "Setting up database with confs: #{database_params}"
          @database_params = database_params
        else
          # Load the yaml file
          if FileTest.exists?(database_params)
            logger.debug "Setting up database using file #{database_params}"
            @database_params = YAML::load(File.open(database_params))['database']
          else
            logger.fatal "The indicated YAML file doesn't exist or is invalid"
            raise BindLogAnalyzer::DatabaseConfsNotValid, "The indicated YAML file doesn't exist or is invalid"
          end
        end
      else
        # Tries to find the yaml file or prints an error
        filename = './database.yml'
        if FileTest.exists?(filename)
            logger.info "No database configurations provided, now trying using #{filename}..."
            @database_params = YAML::load(File.open(filename))['database']
        else
          logger.fatal "Can't find valid database configurations"
          raise BindLogAnalyzer::DatabaseConfsNotValid, "Can't find valid database configurations"
        end
      end
    end
  end
end