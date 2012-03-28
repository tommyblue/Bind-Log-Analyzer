module BindLogAnalyzer
  class Base
    attr_reader :log_filename
    
    def initialize(logfile = nil)
      self.logfile = logfile if logfile
    end

    def logfile=(logfile)
      @log_filename = logfile if FileTest.exists?(logfile)
    end

    def logfile
      @log_filename
    end

    def parse_line(line)
      query = {}
      regexp = %r{^(\d{2}-\w{3}-\d{4})\s+(\d{2}:\d{2}:\d{2})\.\d{3}\s+client\s+(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})#\d+:\s+query:\s+(.*)\s+IN\s+(\w+)\s+\+\s+\((\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\)$}
      
      parsed_line = line.scan(regexp)
      if parsed_line.size > 0
        query[:date]    = parsed_line[0][0]
        query[:time]    = parsed_line[0][1]
        query[:client]  = parsed_line[0][2]
        query[:query]   = parsed_line[0][3]
        query[:type]    = parsed_line[0][4]
        query[:server]  = parsed_line[0][5]
      end

      query
    end

    def print_lines
      File.open(@log_filename).each_line do |l|
        puts l
      end
    end
  end
end