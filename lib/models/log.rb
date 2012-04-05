# The Log object represents a log line of a Bind's query
class Log < ActiveRecord::Base
  
  # Shows 50 top queries
  def self.top_queries
    self.select('query, count(*) as hits').group(:query).order('hits DESC').limit(50)
  end

  # Shows 50 top clients
  def self.top_clients
    self.select('client, count(*) as hits').group(:client).order('hits DESC').limit(50)
  end
end