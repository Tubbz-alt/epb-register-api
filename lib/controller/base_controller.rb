require_relative '../helper/toggles'
require_relative '../container'
require 'sinatra/cross_origin'

module Controller
  class BaseController < Sinatra::Base
    attr_reader :toggles

    def initialize(toggles = false)
      super
      @json_helper = Helper::JsonHelper.new
      @toggles = toggles || Toggles.new
      @container = Container.new
      @logger = Logger.new(STDOUT)
      @events = Helper::EventHelper.new
    end

    configure :development do
      require 'sinatra/reloader'
      register Sinatra::Reloader
      also_reload 'lib/**/*.rb'
    end

    configure do
      enable :cross_origin
      set :protection, except: %i[remote_token]
    end

    before do
      response.headers['Access-Control-Allow-Origin'] = '*'
      response.headers['Access-Control-Allow-Headers'] =
        'Content-Type, Cache-Control, Accept'
    end

    def request_body(schema = false)
      @json_helper.convert_to_ruby_hash(request.body.read.to_s, schema)
    end

    def json_response(code = 200, object)
      content_type :json
      status code
      @json_helper.convert_to_json(object)
    end

    def error_response(response_code = 500, error_code, title)
      json_response(
        response_code,
        { errors: [{ code: error_code, title: title }] }
      )
    end

    def server_error(exception)
      logger.error(exception.message)
      error_response(500, 'SERVER_ERROR', exception.message)
    end

    def not_found_error(title)
      error_response(404, 'NOT_FOUND', title)
    end
  end
end
