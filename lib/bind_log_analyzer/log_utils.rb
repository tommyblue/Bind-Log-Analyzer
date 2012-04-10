require 'bind_log_analyzer/exceptions'
require 'logger'

module BindLogAnalyzer
  # Sets log level
  module LogUtils
    # Sets the log level
    # @param [String] logfile The path to the file containing the Bind's logs to analyze
    def self.set_log_level(log_level)
      log = Logger.new STDOUT

      if log_level > 0
        
        log_level_class = {
          1 => Logger::ERROR,
          2 => Logger::WARN,
          3 => Logger::INFO,
          4 => Logger::DEBUG
        }

        log.level = log_level_class[log_level]
      else
        log.level = Logger::FATAL
      end
      return log
    end
  end
end