require 'bind_log_analyzer/exceptions'
require 'bind_log_analyzer/connector'
require 'models/log'

module BindLogAnalyzer
  # The main class of the BindLogAnalyzer module
  class Base
    include BindLogAnalyzer::Connector

    # @attribute [r]
    # @return [String] The file containing the logs to be analyzed
    attr_reader :log_filename
    
    # The constructor of BindLogAnalyzer::Base sets some vars and manages the setup of the database
    # @param [Hash, String] database_params The path to the database configurations file or a hash containing such informations
    # @param [String] logfile The path to the file containing the Bind's logs to analyze
    # @param [true, false] setup_database A flag which indicates whether to launch the database migration
    # @param [Integer] log_level The level of the log requested by the user
    def initialize(database_params = nil, logfile = nil, setup_database = false, log_level = 0)
      @stored_queries = 0
      self.logfile = logfile if logfile
      setup_db(database_params, setup_database, log_level)
    end

    # Sets the path to the log file checking if exists
    # @param [String] logfile The path to the file containing the Bind's logs to analyze
    def logfile=(logfile)
      @log_filename = logfile if FileTest.exists?(logfile)
    end

    # Returns the path to the Bind's log file
    # @return [String] The path to the Bind's log file
    def logfile
      @log_filename
    end

    # Parses a log line and creates a hash with the informations
    # @param [String] line The query log line to parse
    # @return [Hash, false] The hash containing the parsed line or false if the line couldn't be parsed
    def parse_line(line)
      query = {}
      regexp = %r{^(\d{2}-\w{3}-\d{4}\s+\d{2}:\d{2}:\d{2}\.\d{3})\s+client\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})#\d+:\s+query:\s+(.*)\s+IN\s+(\w+)\s+\+\s+\((\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\)$}
      
      parsed_line = line.scan(regexp)
      if parsed_line.size > 0
        # Parse timestamp
        parsed_timestamp = Date._strptime(parsed_line[0][0], "%d-%b-%Y %H:%M:%S.%L")
        query_time = Time.local(parsed_timestamp[:year], parsed_timestamp[:mon], parsed_timestamp[:mday], parsed_timestamp[:hour], parsed_timestamp[:min], parsed_timestamp[:sec], parsed_timestamp[:sec_fraction], parsed_timestamp[:zone])
        
        query[:date]    = query_time
        query[:client]  = parsed_line[0][1]
        query[:query]   = parsed_line[0][2]
        query[:q_type]  = parsed_line[0][3]
        query[:server]  = parsed_line[0][4]

        query
      else
        false
      end
    end

    # Stores the parsed log line into the database. Increments @stored_queries if successful
    # @param [Hash] query The log line parsed by #parse_line
    def store_query(query)
      log = Log.new(query)
      @stored_queries += 1 if log.save
    end

    # The main method used to manage the analysis operations.
    # Opens the log file and passes wvery line to #parse_line and #store_query
    # @return [true, false] False if there's a problem with the log file. True elsewhere.
    def analyze
      return false unless @log_filename
      
      lines = 0
      File.new(@log_filename).each do |line|
        query = self.parse_line(line)
        if query
          self.store_query(query)
          lines += 1
        end
      end
      puts "Analyzed #{lines} lines and correctly stored #{@stored_queries} logs"
      return true
    end
  end
end