require 'open-uri'

module Commonsense

  class SenseAPI

    attr_accessor :verbose, :use_https

    attr :response, :status, :headers, :error

    def initialize(args={})

      @api_key        = args[:api_key] || ""
      @session_id     = args[:session_id] || ""
      @status         = 0
      @headers        = {}
      @response       = ""
      @error          = ""
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

        else
        end
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
    end



  end

end


