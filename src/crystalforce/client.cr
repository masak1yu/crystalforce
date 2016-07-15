module Crystalforce
  class Client
    include Crystalforce::Api

    def initialize(args : Hash)
      @api_version = ""
      @access_token = ""
      @instance_url = ""
      args[:api_version] = args[:api_version]? ? args[:api_version] : "34.0"
      args[:host] = "login.salesforce.com" unless args[:host]?
      @api_version = args[:api_version]

      response = Crystalforce::Authentication.authenticate(args)
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
