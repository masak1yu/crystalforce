require "./crystalforce/*"

module Crystalforce
  def self.new(
    username : String? = nil,
    password : String? = nil,
    security_token : String? = nil,
    client_id : String? = nil,
    client_secret : String? = nil,
    refresh_token : String? = nil,
    host : String = "login.salesforce.com",
    api_version : String = "34.0"
  )
    Crystalforce::Client.new(
      username: username,
      password: password,
      security_token: security_token,
      client_id: client_id,
      client_secret: client_secret,
      refresh_token: refresh_token,
      host: host,
      api_version: api_version,
    )
  end
end
