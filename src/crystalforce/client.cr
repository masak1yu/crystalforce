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
      host : String = "login.salesforce.com",
      api_version : String = "34.0"
    )
      @api_version = api_version
      @access_token = ""
      @instance_url = ""

      response = Crystalforce::Authentication.authenticate(
        username: username,
        password: password,
        security_token: security_token,
        client_id: client_id,
        client_secret: client_secret,
        refresh_token: refresh_token,
        host: host,
      )
      if response && response.status_code != 200
        raise AuthenticationError.new "No authentication middleware present"
      end

      if response
        res = JSON.parse(response.body)
        @access_token = res["access_token"].to_s
        @instance_url = res["instance_url"].to_s
      end
    end
  end
end
