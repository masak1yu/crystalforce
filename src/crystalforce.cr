require "./crystalforce/*"

module Crystalforce
  def self.new(
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
    authentication_callback : Proc(Client, Nil)? = nil,
    compress : Bool = false,
    proxy_uri : String? = nil,
    ssl : OpenSSL::SSL::Context::Client? = nil,
    request_headers : Hash(String, String)? = nil,
    cache : Cache? = nil,
  )
    Crystalforce::Client.new(
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
