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
      if !parameters.empty? && sensor_id > -1
        url = "/sensors/#{sensor_id}.json"
      else
        url = "/sensors.json"
      end

      sense_api_call(url, :get, parameters)
    end

    def sensors_delete(sensor_id)
      url = "/sensors/#{sensor_id}.json"
      sense_api_call(url, :delete)
    end

    def sensors_post_parameters
      {
      'sensor' => {
        'name'           => '',
        'display_name'   => '',
        'device_type'    => '',
        'pager_type'     => '',
        'data_type'      => '',
        'data_structure' => ''
        }
      }
    end

    def sensors_post(parameters={})
      url = "/sensors.json"
      sense_api_call(url, :post, parameters)
    end

    def sensors_put(sensor_id, parameters={})
      url = "/sensors/#{sensor_id}.json"
      sense_api_call(url, :put, parameters)
    end

    #
    # metatags
    #

    def sensors_metatags_get(parameters={}, namespace='default')
      parameters['namespace'] = namespace
      url = "/sensors/metatags.json"
      sense_api_call(url, :get, parameters)
    end

    def group_sensors_metatags_get(group_id, parameters={}, namespace='default')
      parameters['namespace'] = namespace
      url = "/groups/#{group_id}/sensors/metatags.json"
      sense_api_call(url, :get, parameters)
    end

    def sensor_metatag_get(sensor_id, parameters={}, namespace='default')
      parameters['namespace'] = namespace
      url = "/sensors/#{sensor_id}/sensors/metatags.json"
      sense_api_call(url, :get, parameters)
    end

    def sensor_metatags_post(sensor_id, metatags, parameters={}, namespace='default')
      parameters['namespace'] = namespace
      url = "/sensors/#{sensor_id}/metatags.json?namespace=#{namespace}"
      sense_api_call(url, :post, parameters)
    end

    def sensor_metatags_put(sensor_id, metatags, parameters={}, namespace='default')
      parameters['namespace'] = namespace
      url = "/sensors/#{sensor_id}/metatags.json?namespace=#{namespace}"
      sense_api_call(url, :put, parameters)
    end

    def sensor_metatags_delte
    end

    def sensors_find
    end

    def group_sensors_find
    end

    def metatag_distinct_values_get
    end

    #
    # Sensor data
    #

    def sensor_data_get_parameters
      {
        'page'       => 0,
        'per_page'   => 100,
        'start_date' => 0,
        'end_date'   => 4294967296,
        'date'       => 0,
        'next'       => 0,
        'last'       => 0,
        'sort'       => 'ASC',
        'total'      => 1
      }
    end

    def sensor_data_get
    end

    def sensor_data_post
    end

    def sensor_data_delete
    end

    def sensors_data_post
    end

    #
    # Services
    #

    def services_get
    end

    def services_post_parameters
    end

    def serives_post
    end

    def services_delete
    end

    def services_get_expression
    end

    def services_set_parameters
    end

    def services_set_expression
    end

    def services_set_method
    end

    def services_get_method
    end

    def services_set_use_data_timestamp
    end

    #
    # Users
    #


    def create_user_parameters
      # XXX Hard-coded test user? 
      {
        'user' => {
          'email'    => 'user@example.com',
          'username' => 'herpaderp',
          'password' => '098f6bcd4621d373cade4e832627b4f6',
          'name'     => 'foo',
          'surname'  => 'bar',
          'mobile'   => '0612345678'
        }
      }
    end

    def create_user
    end

    def users_get_current
    end

    def users_update
    end

    def users_delete
    end

    #
    # Events
    #

    def events_notifications_get
    end

    def events_notifications_delete
    end

    def events_notifications_post_parameters
      {
        'event_notification' => {
          'name'            => 'my_event',
          'event'           => 'add_sensor',
          'notification_id' => 0,
          'priority'        => 0
        }
      }
    end

    def events_notifications_post
    end

    #
    # Triggers
    #

    def triggers_get
    end

    def triggers_delete
    end

    def triggers_post_parameters
      {
        'trigger' => {
          'name'       => '',
          'expression' => '',
          'inactivity' => 0
        }
      }
    end

    def triggers_post
    end

    #
    # Sensors triggers
    #

    def sensors_triggers_get
    end

    def sensors_triggers_delete
    end

    def sensors_triggers_post_parameters
      {
        'trigger' => {
          'id' => 0
        }
      }
    end

    def sensors_triggers_post
    end

    def sensors_triggers_put
    end

    def sensors_triggers_toggle_active_parameters
      {
        'active' => 1
      }
    end

    def sensors_triggers_toggle_active
    end

    #
    # Sensors triggers notifications
    #

    def sensors_triggers_notifications_get
    end

    def sensors_triggers_notifications_delete
    end

    def sensors_triggers_notifications_post_parameters
		  # {'notification':{'id':0}}
    end

    def sensors_triggers_notifications_post
    end

    #
    # Notifications
    #

    def notifications_get
    end

    def notifications_delete
    end

    def notifications_post_parameters
		  # {'notification':{'type':'url, email', 'text':'herpaderp', 'destination':'http://api.sense-os.nl/scripts'}}
    end

    def notifications_post
    end

    #
    # Devices
    #

    def sensors_add_to_device_parameters
      # {'device':{'id':0, 'type':'', 'uuid':0}}
    end

    def sensor_add_to_device
    end

    #
    # Groups
    #

    def groups_get_parameters
    end

    def groups_get
    end

    def groups_delete
    end

    def groups_post_parameters
      # {'group': {'name':''}}
    end

    def groups_post
    end

    def groups_put_parameters
    end

    def groups_put
    end

    #
    # Groups & Users
    #

    def groups_users_get_parameters
      {
        'details' => 'full'
      }
    end

    def groups_users_get(parameters, group_id)
    end

    def groups_users_post_parameters
		  # {"users":[{"user":{"id":"", "username":""}}]}
    end

    def groups_users_delete(group_id, user_id)
    end

    #
    # States
    #
    
    def states_default_check
      sense_api_call('/states/default/check.json', :get)
    end

    #
    # Groups & Sensors
    #

    def groups_sensors_post(group_id, sensors)
      sense_api_call("/groups/#{group_id}/sensors.json", :post, sensors)
    end

    def groups_sensors_get(groupd_id, parameters)
      sense_api_call("/groups/#{group_id}/sensors.json", :get, parameters)
    end

    def groups_sensors_delete(group_id, sensor_id)
      sense_api_call("/groups/#{group_id}/sensors/#{sensor_id}.json", :delete)
    end

    #
    # Domains
    #

    def domains_get_parameters
		  {
        'details'     => 'full',
        'page'        => 0,
        'per_page'    => 100,
        'total'       => 0,
        'member_type' => 'member'
      }
    end












  end

end


