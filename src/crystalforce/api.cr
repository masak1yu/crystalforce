require "json"

module Crystalforce
  module Api
    def query(soql)
      query_str = URI.escape(soql)
      response = HTTP::Client.get "#{api_path}/query/?q=#{query_str}",
        HTTP::Headers{"Authorization" => "Bearer #{@access_token}"}
      if response && response.status_code != 200
        raise ServerError.new "Cannot connect salesforce"
      end
      result = JSON.parse(response.body)
      result["records"]
    end

    def query_all(soql)
      query_str = URI.escape(soql)
      response = HTTP::Client.get "#{api_path}/queryAll/?q=#{query_str}",
        HTTP::Headers{"Authorization" => "Bearer #{@access_token}"}
      if response && response.status_code != 200
        raise ServerError.new "Cannot connect salesforce"
      end
      result = JSON.parse(response.body)
      result["records"]
    end

    # FIXME
    def search(sosl)
      query_str = URI.escape(sosl)
      p query_str
      response = HTTP::Client.get "#{api_path}/search/?q=#{query_str}", HTTP::Headers{"Authorization" => "Bearer #{@access_token}"}
      if response && response.status_code != 200
        raise ServerError.new "Cannot connect salesforce"
      end
      result = JSON.parse(response.body)
    end

    def create(sobject, attrs)
      HTTP::Client.post "#{api_path}/sobjects/#{sobject}/", HTTP::Headers{"Authorization" => "Bearer #{@access_token}", "Content-Type" => "application/json"}, attrs.to_json
    end

    def update(sobject, id, attrs)
      HTTP::Client.patch "#{api_path}/sobjects/#{sobject}/#{id}", HTTP::Headers{"Authorization" => "Bearer #{@access_token}", "Content-Type" => "application/json"}, attrs.to_json
    end

    def destroy(sobject, id)
      HTTP::Client.delete "#{api_path}/sobjects/#{sobject}/#{id}", HTTP::Headers{"Authorization" => "Bearer #{@access_token}"}
    end

    private def api_path
      "#{@instance_url}/services/data/v#{@api_version}"
    end
  end
end
