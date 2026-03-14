module Crystalforce
  # Read config from environment variables
  def self.env_username : String?
    ENV["SALESFORCE_USERNAME"]?
  end

  def self.env_password : String?
    ENV["SALESFORCE_PASSWORD"]?
  end

  def self.env_security_token : String?
    ENV["SALESFORCE_SECURITY_TOKEN"]?
  end

  def self.env_client_id : String?
    ENV["SALESFORCE_CLIENT_ID"]?
  end

  def self.env_client_secret : String?
    ENV["SALESFORCE_CLIENT_SECRET"]?
  end

  def self.env_host : String?
    ENV["SALESFORCE_HOST"]?
  end

  def self.env_api_version : String?
    ENV["SALESFORCE_API_VERSION"]?
  end

  def self.env_proxy_uri : String?
    ENV["SALESFORCE_PROXY_URI"]?
  end
end
