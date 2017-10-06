require "http/client"
require "openssl"

module Crystalforce
  class Authentication
    # Public: Force an authentication
    def self.authenticate(options)
      context = OpenSSL::SSL::Context::Client.new
      if username_password?(options)
        HTTP::Client.post_form "https://#{options[:host]}/services/oauth2/token",
          "grant_type=password&client_id=#{options[:client_id]}&client_secret=#{options[:client_secret]}&username=#{options[:username]}&password=#{options[:password]}",
          tls: context
      elsif oauth_refresh?(options)
        HTTP::Client.post_form "https://#{options[:host]}/services/oauth2/token",
          "grant_type=refresh_token&refresh_token=#{options[:refresh_token]}&client_id=#{options[:client_id]}&client_secret=#{options[:client_secret]}",
          tls: context
      end
    end

    # Internal: Returns true if username/password (autonomous) flow should be used for
    # authentication.
    def self.username_password?(options)
      options[:username]? &&
        options[:password]? &&
        options[:client_id]? &&
        options[:client_secret]?
    end

    # Internal: Returns true if oauth token refresh flow should be used for
    # authentication.
    def self.oauth_refresh?(options)
      options[:refresh_token]? &&
        options[:client_id]? &&
        options[:client_secret]?
    end
  end
end
