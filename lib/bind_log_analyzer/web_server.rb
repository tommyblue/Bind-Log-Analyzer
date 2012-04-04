require 'json'
require 'sinatra'
require 'haml'
require 'models/log'

module BindLogAnalyzer
  # The webserver
  class WebServer < Sinatra::Application

    set :static, true
    set :public_folder, File.expand_path('../../../resources/assets/', __FILE__)
  
    set :views,  File.expand_path('../../../resources/views/', __FILE__)
    set :haml, { :format => :html5 }

    # Root serving Backbone.js
    get '/' do
      @logs = Log.limit(30)
      haml :index, :layout => :layout
    end

    get '/pippo' do
      content_type :json
      { :key1 => 'value1', :key2 => 'value2' }.to_json
    end
  end
end