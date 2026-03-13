require "http/client"

module Crystalforce
  class Authentication
    def self.authenticate(
      username : String? = nil,
      password : String? = nil,
      security_token : String? = nil,
      client_id : String? = nil,
      client_secret : String? = nil,
      refresh_token : String? = nil,
      host : String = "login.salesforce.com"
    )
      if username && password && client_id && client_secret
        HTTP::Client.post "https://#{host}/services/oauth2/token",
          form: "grant_type=password&client_id=#{client_id}&client_secret=#{client_secret}&username=#{username}&password=#{password}"
      elsif refresh_token && client_id && client_secret
        HTTP::Client.post "https://#{host}/services/oauth2/token",
          form: "grant_type=refresh_token&refresh_token=#{refresh_token}&client_id=#{client_id}&client_secret=#{client_secret}"
      end
    end
  end
end
