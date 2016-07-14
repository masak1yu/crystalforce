# require "./crystalforce/*"
require "http/client"
require "json"

module Crystalforce
  class Error < Exception; end
  class ServerError < Error; end
  class AuthenticationError < Error; end
  class UnauthorizedError < Error; end
  class APIVersionError < Error; end

  def self.new(args : Hash)
  	Crystalforce::Data::Client.new(args)
  end
end

module Crystalforce
  module Data
    class Client
      def initialize(args : Hash)
        args[:api_version] = "34.0" unless args[:api_version]?
        args[:host] = "login.salesforce.com" unless args[:host]?
        @api_version = args[:api_version]

        response = Crystalforce::Concerns::Authentication.authenticate(args)
        raise AuthenticationError, 'No authentication middleware present' if response.status_code != 200

        res = JSON.parse(response.body)
        @access_token = res["access_token"].to_s
        @instance_url = res["instance_url"].to_s
        #query = "select Id, Name from Testobj__c".gsub(" ", "+")
        # account_res = HTTP::Client.get instance_url + "/services/data/v" + api_version + "/sobjects/Account/",
        #  HTTP::Headers{"Authorization" => "Bearer #{access_token}"}
      end

      def query(q)
      	q.gsub!(" ", "+")
        response = HTTP::Client.get @instance_url + "/services/data/v" + @api_version + "/query/?q=#{q}",
          HTTP::Headers{"Authorization" => "Bearer #{@access_token}"}
        raise ServerError, 'Cannot connect salesforce' if response.status_code != 200
        JSON.parse(response.body)
      end
    end
  end
end

module Crystalforce
  module Concerns
    class Authentication
      # Public: Force an authentication
      def self.authenticate(options)
        if username_password?(options)
          HTTP::Client.post_form "https://#{options[:host]}/services/oauth2/token",
            "grant_type=password"
            + "&client_id=#{options[:client_id]}&client_secret=#{options[:client_secret]}"
            + "&username=#{options[:username]}&password=#{options[:password]}"
        elsif oauth_refresh?(options)
          HTTP::Client.post_form "https://#{options[:host]}/services/oauth2/token",
            "grant_type=refresh_token"
            + "&refresh_token=#{options[:refresh_token]}&client_id=#{options[:client_id]}"
            + "&client_secret=#{options[:client_secret]}"
        end
      end

      # Internal: Returns true if username/password (autonomous) flow should be used for
      # authentication.
      def username_password?(options)
        options[:username]? &&
          options[:password]? &&
          options[:client_id]? &&
          options[:client_secret]?
      end

      # Internal: Returns true if oauth token refresh flow should be used for
      # authentication.
      def oauth_refresh?(options)
        options[:refresh_token]? &&
          options[:client_id]? &&
          options[:client_secret]?
      end
    end
  end
end
