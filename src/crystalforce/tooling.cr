module Crystalforce
  class ToolingClient
    include Crystalforce::Api

    def initialize(
      username : String? = nil,
      password : String? = nil,
      security_token : String? = nil,
      client_id : String? = nil,
      client_secret : String? = nil,
      refresh_token : String? = nil,
      jwt_key : String? = nil,
      host : String? = nil,
      api_version : String? = nil,
      authentication_retries : Int32 = 3,
      authentication_callback : Proc(ToolingClient, Nil)? = nil,
      compress : Bool = false,
      proxy_uri : String? = nil,
      ssl : OpenSSL::SSL::Context::Client? = nil,
      request_headers : Hash(String, String)? = nil,
      cache : Cache? = nil,
    )
      @username = username || Crystalforce.env_username
      @password = password || Crystalforce.env_password
      @security_token = security_token || Crystalforce.env_security_token
      @client_id = client_id || Crystalforce.env_client_id
      @client_secret = client_secret || Crystalforce.env_client_secret
      @host = host || Crystalforce.env_host || "login.salesforce.com"
      @api_version = api_version || Crystalforce.env_api_version || "34.0"
      @proxy_uri = proxy_uri || Crystalforce.env_proxy_uri

      @refresh_token = refresh_token
      @jwt_key = jwt_key
      @authentication_retries = authentication_retries
      @authentication_callback = authentication_callback
      @compress = compress
      @ssl = ssl
      @request_headers = request_headers
      @cache = cache

      @access_token = ""
      @instance_url = ""

      perform_authentication
    end

    getter access_token : String
    getter instance_url : String

    protected def perform_authentication
      Crystalforce::Log.info { "Authenticating Tooling client with #{@host}" }
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

    private def api_path
      "#{@instance_url}/services/data/v#{@api_version}/tooling"
    end
  end

  def self.tooling(
    username : String? = nil,
    password : String? = nil,
    security_token : String? = nil,
    client_id : String? = nil,
    client_secret : String? = nil,
    refresh_token : String? = nil,
    jwt_key : String? = nil,
    host : String? = nil,
    api_version : String? = nil,
    authentication_retries : Int32 = 3,
    authentication_callback : Proc(ToolingClient, Nil)? = nil,
    compress : Bool = false,
    proxy_uri : String? = nil,
    ssl : OpenSSL::SSL::Context::Client? = nil,
    request_headers : Hash(String, String)? = nil,
    cache : Cache? = nil,
  )
    ToolingClient.new(
      username: username,
      password: password,
      security_token: security_token,
      client_id: client_id,
      client_secret: client_secret,
      refresh_token: refresh_token,
      jwt_key: jwt_key,
      host: host,
      api_version: api_version,
      authentication_retries: authentication_retries,
      authentication_callback: authentication_callback,
      compress: compress,
      proxy_uri: proxy_uri,
      ssl: ssl,
      request_headers: request_headers,
      cache: cache,
    )
  end
end
