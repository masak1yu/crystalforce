require "json"
require "uri"

module Crystalforce
  module Api
    def query(soql)
      query_str = URI.encode_www_form(soql)
      response = with_retry do
        HTTP::Client.get "#{api_path}/query/?q=#{query_str}",
          headers: auth_headers
      end
      if response.status_code != 200
        raise ServerError.new "Cannot connect salesforce"
      end
      result = JSON.parse(response.body)
      result["records"]
    end

    def query_all(soql)
      query_str = URI.encode_www_form(soql)
      response = with_retry do
        HTTP::Client.get "#{api_path}/queryAll/?q=#{query_str}",
          headers: auth_headers
      end
      if response.status_code != 200
        raise ServerError.new "Cannot connect salesforce"
      end
      result = JSON.parse(response.body)
      result["records"]
    end

    def search(sosl)
      query_str = URI.encode_www_form(sosl)
      response = with_retry do
        HTTP::Client.get "#{api_path}/search/?q=#{query_str}",
          headers: auth_headers
      end
      if response.status_code != 200
        raise ServerError.new "Cannot connect salesforce"
      end
      JSON.parse(response.body)
    end

    def create(sobject, attrs)
      with_retry do
        HTTP::Client.post "#{api_path}/sobjects/#{sobject}/",
          headers: auth_headers_with_json,
          body: attrs.to_json
      end
    end

    def update(sobject, id, attrs)
      with_retry do
        HTTP::Client.patch "#{api_path}/sobjects/#{sobject}/#{id}",
          headers: auth_headers_with_json,
          body: attrs.to_json
      end
    end

    def upsert(sobject, field, attrs)
      external_id = attrs.fetch(attrs.keys.find { |k| k.to_s.downcase == field.to_s.downcase }, nil)
      attrs_without_field = attrs.reject { |k, v| k.to_s.downcase == field.to_s.downcase }
      response = with_retry do
        HTTP::Client.patch "#{api_path}/sobjects/#{sobject}/#{field}/#{URI.encode_www_form(external_id.not_nil!.to_s)}",
          headers: auth_headers_with_json,
          body: attrs_without_field.to_json
      end
      (response.body && response.body["id"]) ? response.body["id"] : true
    end

    def destroy(sobject, id)
      with_retry do
        HTTP::Client.delete "#{api_path}/sobjects/#{sobject}/#{id}",
          headers: auth_headers
      end
    end

    private def api_path
      "#{@instance_url}/services/data/v#{@api_version}"
    end

    private def auth_headers
      HTTP::Headers{"Authorization" => "Bearer #{@access_token}"}
    end

    private def auth_headers_with_json
      HTTP::Headers{"Authorization" => "Bearer #{@access_token}", "Content-Type" => "application/json"}
    end
  end
end
