# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "bind_log_analyzer/version"

Gem::Specification.new do |s|
  s.name        = "bind_log_analyzer"
  s.version     = BindLogAnalyzer::VERSION
  s.authors     = ["Tommaso Visconti"]
  s.email       = ["tommaso.visconti@gmail.com"]
  s.homepage    = "https://github.com/tommyblue/Bind-Log-Analyzer"
  s.summary     = %q{Log analysis and SQL storage for Bind DNS server}
  s.description = %q{BindLogAnalyzer analyzes a Bind query log file and stores its data into a SQL database using ActiveRecord. It provides a fancy web interface to show some query stats and graphs.}

  s.rubyforge_project = "bind_log_analyzer"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_dependency "activerecord"
  s.add_dependency "json"
  s.add_dependency "sinatra"
  s.add_dependency "haml"
  s.add_development_dependency "rspec"
  s.add_development_dependency "simplecov"
end
