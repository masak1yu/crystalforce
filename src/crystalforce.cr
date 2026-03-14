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
    host : String = "login.salesforce.com",
    api_version : String = "34.0",
    authentication_retries : Int32 = 3,
    authentication_callback : Proc(Client, Nil)? = nil
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
    )
  end
end
