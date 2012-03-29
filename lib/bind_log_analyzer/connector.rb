module BindLogAnalyzer
  module Connector
    def connect
      #@db_config = YAML::load(File.open(File.join(File.dirname(__FILE__),'..', 'config.yml')))['database']
      ActiveRecord::Base.establish_connection({"adapter"=>"mysql2", "database"=>"bindlogsql", "host"=>"localhost", "port"=>3306, "username"=>"root", "password"=>nil})
      #Dir.glob('./lib/models/*').each { |r| require r }
    end

    def connected?
      ActiveRecord::Base.connected?
    end
  end
end