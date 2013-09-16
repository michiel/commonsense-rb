require 'open-uri'
require 'net/http'
require 'net/https'

module Commonsense

  class SenseAPI

    attr_accessor :verbose, :use_https

    attr :response, :status, :headers, :error

    def initialize(args={})

      @api_key        = args[:api_key] || ""
      @session_id     = args[:session_id] || ""
      @status         = 0
      @headers        = {}
      @response       = nil
      @error          = nil
      @verbose        = false
      @server         = :live
      @server_url     = 'api.sense-os.nl'
      @authentication = :not_authenticated
      @oauth_consumer = {}
      @oauth_token    = {}
      @use_https      = true

      @valid_authentication_methods = [
        :session_id,
        :oauth,
        :authenticating_session_id,
        :authenticating_oauth,
        :not_authenticated,
        :api_key
      ]

    end

    #
    # get methods
    #

    def get_location_id
      # TODO
    end

    #
    # set methods
    #

    def set_server(server)
      @server = server
      case server
      when :live then
        @server_url = 'api.sense-os.nl'
        @use_https = true
      when :dev then
        @server_url = 'api.dev.sense-os.nl'
        @use_https = false
      when :rc then
        @server_url = 'api.rc.dev.sense-os.nl'
        @use_https = false
      else
        raise Exception "No valid server type specified!"
      end
    end

    def set_authentication_method(method)
      if !@valid_authentication_methods.include?(method)
        raise Exception "No valid authentication type specified!"
      else
        @authentication = method
      end
    end

    #
    # Base API calls
    # XX : This method could benefit from some refactoring
    #

    def sense_api_call(url, method, parameters={}, headers={})
      heads    = headers.clone
      body     = ''
      http_url = ''

      #
      # This seems to be the default, override as necessary
      #

      heads["Content-type"] = "application/json"
      heads["Accept"]       = "*"

      if (
        @authentication == :not_authenticated and
        url             == '/users.json' and
        method          == :post
      )
        # Authenticating a user
      
        body = parameters.to_json

      else

        # Authenticated API calls
        
        case @authentication

        when :not_authenticated
          @status = 401
          return false

        when :authenticating_oauth
          heads["Content-type"] = "application/x-www-form-urlencoded"
          http_url = "#{@url}?#{URI.encode_www_form(parameters)}"

        when :authenticating_session_id
          body = parameters.to_json

        when :oauth
          # TODO
          # oauth_url = "http://#{@server_url}#{url}"

        when :session_id
          heads['X-SESSION_ID'] = @session_id
          if !parameters.empty?
            if (method == :get or method == :delete)
              heads["Content-type"] = "application/x-www-form-urlencoded"
              http_url = "#{@url}?#{URI.encode_www_form(parameters)}"
            else
              body = parameters.to_json
            end
          end

        when :api_key
          parameters['API_KEY'] = @api_key
          if (method == :get or method == :delete)
            heads["Content-type"] = "application/x-www-form-urlencoded"
            http_url = "#{@url}?#{URI.encode_www_form(parameters)}"
          else
            body = parameters.to_json
          end

        else
          @status = 418
          return false
        end

      end

      #
      # Call server
      # TODO : move to own method
      #

      begin
        server = Net::HTTP.new(@server_url, @use_https ? 443 : 80)
        server.use_ssl = @use_https

        server.start do |http|
          klass = case @method
          when :get then Net::HTTP::Get
          when :post then Net::HTTP::Post
          when :delete then Net::HTTP::Delete
          else
            raise Exception "No valid http method passed!"
          end
          request  = klass.new(url)
          response = http.request(request)
          resp     = response.body
        end

      rescue SocketError
        raise "Host " + host + " unavailable"
      end

      # @headers  = {}
      # @response = 
      # @stats    = @response.status

      # TODO : Set headers from response - sets cookies?

      if @status == 200 || @status == 201 || @status == 302
        true
      else
        false
      end

    end

    #
    # Session id auth
    #
    
    def set_api_key(api_key)
      @api_key = api_key
      set_authentication_method(:api_key)
    end

    def set_session_id(session_id)
      @session_id = session_id
      set_authentication_method(:session_id)
    end

    def authenticate_session_id(username, password)
      set_authentication_method(:authenticating_session_id)

      parameters = {
        'username' => username,
        'password' => password
      }

      response = {}

      if sense_api_call('/login.json', :post, parameters)

        begin
          response = JSON.parse(@response)
        rescue Exception => e
          response = {}
          set_not_authenticated("notjson : #{e.to_s}")
          return false
        end

        if response['session_id'].nil?
          set_not_authenticated('no session_id')
          false
        else
          @session_id = response['session_id']
          set_authentication_method(:session_id)
          false
        end

      else
        set_not_authenticated('api call unsuccessful')
        false
      end
    end

    def logout_session_id
      if sense_api_call('/logout.json', :post)
        set_authentication_method(:not_authenticated)
      else
        @error = 'api call unsuccessful'
      end
    end

    def set_not_authenticated(reason='no idea')
      set_authentication_method(:not_authenticated)
      @error = reason
      false
    end

    #
    # TODO : OAuth
    # 

    #
    # Sensors
    #

    def sensors_get_parameters
      { 
        'page'     => 0,
        'per_page' => 100,
        'shared'   => 0,
        'owned'    => 0,
        'physical' => 0,
        'details'  => 'full'
      }
    end

    def sensors_get(parameters={}, sensor_id=-1)
      url = ''
    end


  end

end


