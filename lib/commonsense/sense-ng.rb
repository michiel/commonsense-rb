require 'faraday'
require 'digest/md5'
require 'json'
require 'logger'

module Commonsense

  class SenseNG

    attr_accessor :use_https, :verbose

    def initialize(args={})
      set_server(args[:server] || :live)
      init_server
    end

    def set_server(server)
      log "Setting server to #{server.to_s} env"
      @server = server
      case server
      when :live then
        @server_url = 'https://api.sense-os.nl'
        @use_https = true
      when :dev then
        @server_url = 'http://api.dev.sense-os.nl'
        @use_https = false
      when :rc then
        @server_url = 'http://api.rc.dev.sense-os.nl'
        @use_https = false
      else
        raise Exception, "No valid server type specified!"
      end
    end

    def login(username, password)
      md5hash =Digest::MD5.hexdigest(password)

      params = {
        'username' => username,
        'password' => md5hash
      }

      res = call(:post, '/login.json', params)
      @session_id = res.env[:response_headers]["X-SESSION_ID"] 
    end

    def get_all(type)
      res_to_json(call_get("/#{type}.json"))
    end

    def get(type, id)
      res_to_json(call_get("/#{type}/#{id}.json"))
    end

    def post(type, id, obj)
      res_to_json(call(:post, "/#{type}/#{id}.json", obj))
    end

    def put(type, id, obj)
      res_to_json(call(:put, "/#{type}/#{id}.json", obj))
    end

    def delete(type, id)
      res_to_json(call(:delete, "/#{type}/#{id}.json"))
    end

    private

    def init_server
      @conn = Faraday.new(:url => @server_url) do |f|
        f.request  :url_encoded
        f.response :logger if @verbose
        f.adapter  Faraday.default_adapter
      end
    end

    def call(method, path, params={})
      log "#{method.to_s}'ing #{path} with #{params.to_s}"
      @conn.send(method) do |req|
        req_set_json req
        req_set_session req
        req.url path
        req.body = params.to_json
      end
    end

    def call_get(path, params={})
      log "get'ing #{path} with #{params.to_s}"
      @conn.get do |req|
        req_set_session req
        req.url path, params
      end
    end

    def log(msg)
      puts msg if @verbose
    end

    def req_set_json(req)
      req.headers['Content-Type'] = 'application/json'
    end

    def req_set_session(req)
      req.headers['X-SESSION_ID'] = @session_id if @session_id
    end

    def res_to_json(res)
      JSON.parse(res.env[:body])
    end

  end

end


