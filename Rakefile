$:.push File.expand_path("../lib", __FILE__)
require "bind_log_analyzer/version"

require 'rubygems'
require 'rspec/core/rake_task'
require "bundler/gem_tasks"

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
  system "gem push bind_log_analyzer-#{BindLogAnalyzer::VERSION}"
end