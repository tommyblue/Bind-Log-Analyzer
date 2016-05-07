require 'bind_log_analyzer/exceptions'
require 'bind_log_analyzer/log_utils'
require 'bind_log_analyzer/connector'
require 'models/log'

module BindLogAnalyzer
  # The main class of the BindLogAnalyzer module
  class Base
    include BindLogAnalyzer::LogUtils
    include BindLogAnalyzer::Connector

    # @attribute [r]
    # @return [String] The file containing the logs to be analyzed
    attr_reader :log_filename

    # The constructor of BindLogAnalyzer::Base sets some vars and manages the setup of the database
    # @param [Hash, String] database_params The path to the database configurations file or a hash containing such informations
    # @param [String] logfile The path to the file containing the Bind's logs to analyze
    # @param [true, false] setup_database A flag which indicates whether to launch the database migration
    # @param [Integer] log_level The level of the log requested by the user
    # @param [true, false] check_uniq Checks if a record exists before creating it
    def initialize(database_params = nil, logfile = nil, setup_database = false, log_level = 0, check_uniq = false)
      @stored_queries = 0
      @check_uniq = check_uniq

      @log = BindLogAnalyzer::LogUtils.set_log_level(log_level)

      self.logfile = logfile if logfile
      setup_db(database_params, setup_database)
    end

    # Sets the path to the log file checking if exists
    # @param [String] logfile The path to the file containing the Bind's logs to analyze
    def logfile=(logfile)
      if FileTest.exists?(logfile)
        @log_filename = logfile
      else
        @log.error("The provided log file doesn't exist")
      end
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
      regexp =     /^(\d{2}-\w{3}-\d{4}\s+\d{2}:\d{2}:\d{2}\.\d{3})\s+client\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})#\d+\s+\(.+\):\s+query:\s+(.*)\s+IN\s+(\w+)\s+\+\s+\((\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\)$/
      old_regexp = /^(\d{2}-\w{3}-\d{4}\s+\d{2}:\d{2}:\d{2}\.\d{3})\s+client\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})#\d+:\s+query:\s+(.*)\s+IN\s+(\w+)\s+\+\s+\((\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\)$/
      regexp_ipv6 = /^(\d{2}-\w{3}-\d{4}\s+\d{2}:\d{2}:\d{2}\.\d{3})\s+client\s+([0-9a-fA-F:]+)#\d+\s+\(.+\):\s+query:\s+(.*)\s+IN\s+(\w+)\s+\+\s+\(([0-9a-fA-F:]+)\)$/


      parsed_line = line.scan(regexp)
      # Try the old version
      if parsed_line.size == 0
        parsed_line = line.scan(old_regexp)
      end
      if parsed_line.size == 0
        parsed_line = line.scan(regexp_ipv6)
      end

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
        @log.error "Can't parse the line: \"#{line}\""
        false
      end
    end

    # Stores the parsed log line into the database and increments @stored_queries if successful.
    # It checks the uniqueness of a record if the @check_uniq flag is set
    # @param [Hash] query The log line parsed by #parse_line
    def store_query(query)
      if @check_uniq
        unless Log.where(query)
          log = Log.new(:date => query[:date])
          @stored_queries += 1 if log.save
        else
          @log.warn "Skipping duplicate entry: #{query}"
        end
      else
        log = Log.new(query)
        if log.save
          @stored_queries += 1
        else
          @log.error "Error saving the log #{query}"
        end
      end
    end

    # The main method used to manage the analysis operations.
    # Opens the log file and passes wvery line to #parse_line and #store_query
    # @return [true, false] False if there's a problem with the log file. True elsewhere.
    def analyze
      return false unless @log_filename

      lines = 0
      File.new(@log_filename).each do |line|
        @log.debug "Got line: \"#{line}\""
        query = self.parse_line(line)
        if query
          @log.debug "Storing line: \"#{query}\""
          self.store_query(query)
          lines += 1
        end
      end
      puts "Analyzed #{lines} lines and correctly stored #{@stored_queries} logs"
      return true
    end
  end
end
