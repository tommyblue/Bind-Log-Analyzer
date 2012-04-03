$:.push File.expand_path("../lib", __FILE__)

require "bind_log_analyzer/version"

require 'rubygems'
require 'rspec/core/rake_task'
require "bundler/gem_tasks"

require 'yaml'
require 'logger'
require 'active_record'

namespace :spec do
  desc "Run all specs"
  RSpec::Core::RakeTask.new(:spec) do |t|
    #t.pattern = 'spec/**/*_spec.rb'
    t.rspec_opts = ['--options', 'spec/spec.opts']
  end

  desc "Generate code coverage"
  RSpec::Core::RakeTask.new(:coverage) do |t|
    #t.pattern = "./spec/**/*_spec.rb" # don't need this, it's default.
    require 'simplecov'
    SimpleCov.start
    #t.rcov = true
    #t.rcov_opts = ['--exclude', 'spec']
  end
end

task :build do
  system "gem build bind_log_analyzer.gemspec"
end
 
task :release => :build do
  system "gem push pkg/bind_log_analyzer-#{BindLogAnalyzer::VERSION}.gem"
end

namespace :db do
  def create_database config
    options = {:charset => 'utf8', :collation => 'utf8_unicode_ci'}

    create_db = lambda do |config|
      ActiveRecord::Base.establish_connection config.merge('database' => nil)
      ActiveRecord::Base.connection.create_database config['database'], options
      ActiveRecord::Base.establish_connection config
    end

    begin
      create_db.call config
    rescue Mysql::Error => sqlerr
      if sqlerr.errno == 1405
        print "#{sqlerr.error}. \nPlease provide the root password for your mysql installation\n>"
        root_password = $stdin.gets.strip

        grant_statement = <<-SQL
GRANT ALL PRIVILEGES ON #{config['database']}.*
TO '#{config['username']}'@'localhost'
IDENTIFIED BY '#{config['password']}' WITH GRANT OPTION;
SQL

        create_db.call config.merge('database' => nil, 'username' => 'root', 'password' => root_password)
      else
        $stderr.puts sqlerr.error
        $stderr.puts "Couldn't create database for #{config.inspect}, charset: utf8, collation: utf8_unicode_ci"
        $stderr.puts "(if you set the charset manually, make sure you have a matching collation)" if config['charset']
      end
    end
  end
 
  task :environment do
    DATABASE_ENV = ENV['DATABASE_ENV'] || 'development'
    MIGRATIONS_DIR = ENV['MIGRATIONS_DIR'] || 'db/migrate'
  end

  task :configuration => :environment do
    @config = YAML.load_file('config/databases.yml')[DATABASE_ENV]
  end

  task :configure_connection => :configuration do
    ActiveRecord::Base.establish_connection @config
    ActiveRecord::Base.logger = Logger.new STDOUT if @config['logger']
  end

  desc 'Create the database from config/database.yml for the current DATABASE_ENV'
  task :create => :configure_connection do
    create_database @config
  end

  desc 'Drops the database for the current DATABASE_ENV'
  task :drop => :configure_connection do
    ActiveRecord::Base.connection.drop_database @config['database']
  end

  desc 'Migrate the database (options: VERSION=x, VERBOSE=false).'
  task :migrate => :configure_connection do
    ActiveRecord::Migration.verbose = true
    ActiveRecord::Migrator.migrate MIGRATIONS_DIR, ENV['VERSION'] ? ENV['VERSION'].to_i : nil
  end

  desc 'Rolls the schema back to the previous version (specify steps w/ STEP=n).'
  task :rollback => :configure_connection do
    step = ENV['STEP'] ? ENV['STEP'].to_i : 1
    ActiveRecord::Migrator.rollback MIGRATIONS_DIR, step
  end

  desc "Retrieves the current schema version number"
  task :version => :configure_connection do
    puts "Current version: #{ActiveRecord::Migrator.current_version}"
  end
end