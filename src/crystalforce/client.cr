module Crystalforce
  class Client
    include Crystalforce::Api

    def initialize(
      username : String? = nil,
      password : String? = nil,
      security_token : String? = nil,
      client_id : String? = nil,
      client_secret : String? = nil,
      refresh_token : String? = nil,
      jwt_key : String? = nil,
      host : String = "login.salesforce.com",
      api_version : String = "34.0",
      authentication_retries : Int32 = 3,
      authentication_callback : Proc(Client, Nil)? = nil
    )
      @api_version = api_version
      @access_token = ""
      @instance_url = ""
      @authentication_retries = authentication_retries
      @authentication_callback = authentication_callback

      # Store auth params for re-authentication
      @username = username
      @password = password
      @security_token = security_token
      @client_id = client_id
      @client_secret = client_secret
      @refresh_token = refresh_token
      @jwt_key = jwt_key
      @host = host

      perform_authentication
    end

    getter access_token : String
    getter instance_url : String

    protected def perform_authentication
      response = Crystalforce::Authentication.authenticate(
        username: @username,
        password: @password,
        security_token: @security_token,
        client_id: @client_id,
        client_secret: @client_secret,
        refresh_token: @refresh_token,
        jwt_key: @jwt_key,
        host: @host,
      )
      if response && response.status_code != 200
        body = JSON.parse(response.body) rescue nil
        error_desc = body.try(&.["error_description"]?.try(&.as_s)) || "Authentication failed"
        raise AuthenticationError.new(error_desc)
      end

      if response
        res = JSON.parse(response.body)
        @access_token = res["access_token"].to_s
        @instance_url = res["instance_url"].to_s
        @authentication_callback.try(&.call(self))
      else
        raise AuthenticationError.new("No valid authentication parameters provided")
      end
    end

    protected def with_retry(&)
      retries = 0
      loop do
        response = yield
        if response.is_a?(HTTP::Client::Response) && response.status_code == 401 && retries < @authentication_retries
          retries += 1
          perform_authentication
        else
          return response
        end
      end
    end
  end
end
