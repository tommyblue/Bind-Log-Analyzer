require 'bind_log_analyzer/exceptions'
require 'bind_log_analyzer/connector'
require 'models/log'

module BindLogAnalyzer
  class Base
    include BindLogAnalyzer::Connector

    attr_reader :log_filename, :database_confs
    
    def initialize(database_confs = nil, logfile = nil, enable_logs = true)
      if database_confs
        if database_confs.instance_of?(Hash)
          @database_confs = database_confs
        else
          # Load the yaml file
          if FileTest.exists?(database_confs)
            @database_confs = YAML::load(File.open(database_confs))['database']
          else
            raise BindLogAnalyzer::DatabaseConfsNotValid, "The indicated YAML file doesn't exist or is invalid"
          end
        end
      else
        # Tries to find the yaml file or prints an error
        filename = File.join(File.dirname(__FILE__), 'database.yml')
        if FileTest.exists?(filename)
            @database_confs = YAML::load(File.open(filename))['database']
        else
          raise BindLogAnalyzer::DatabaseConfsNotValid, "Can't find valid database configurations"
        end
      end
      
      self.logfile = logfile if logfile
      setup_db(@database_confs, enable_logs)
    end

    def logfile=(logfile)
      @log_filename = logfile if FileTest.exists?(logfile)
    end

    def logfile
      @log_filename
    end

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

    def print_lines
      File.open(@log_filename).each_line do |l|
        puts l
      end
    end

    def store_query(query)
      log = Log.new(query)
      log.save
    end

    def analyze
      return false unless @log_filename
      
      File.new(@log_filename).each do |line|
        query = self.parse_line(line)
        self.store_query(query) if query
      end
    end
  end
end