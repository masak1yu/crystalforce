require "json"
require "uri"

module Crystalforce
  module Api
    # Low-level HTTP verbs

    def api_get(path, params = nil)
      url = "#{api_path}#{path}"
      url += "?#{URI::Params.encode(params)}" if params
      response = with_retry do
        HTTP::Client.get url, headers: auth_headers
      end
      response
    end

    def api_post(path, body = nil)
      json_body = body ? (body.is_a?(String) ? body : body.to_json) : nil
      with_retry do
        HTTP::Client.post "#{api_path}#{path}",
          headers: auth_headers_with_json,
          body: json_body
      end
    end

    def api_patch(path, body = nil)
      json_body = body ? (body.is_a?(String) ? body : body.to_json) : nil
      with_retry do
        HTTP::Client.patch "#{api_path}#{path}",
          headers: auth_headers_with_json,
          body: json_body
      end
    end

    def api_put(path, body = nil)
      json_body = body ? (body.is_a?(String) ? body : body.to_json) : nil
      with_retry do
        HTTP::Client.put "#{api_path}#{path}",
          headers: auth_headers_with_json,
          body: json_body
      end
    end

    def api_delete(path)
      with_retry do
        HTTP::Client.delete "#{api_path}#{path}",
          headers: auth_headers
      end
    end

    # Query

    def query(soql)
      response = api_get("/query/", {"q" => soql})
      raise_on_error(response)
      result = JSON.parse(response.body)
      result["records"]
    end

    def query_all(soql)
      response = api_get("/queryAll/", {"q" => soql})
      raise_on_error(response)
      result = JSON.parse(response.body)
      result["records"]
    end

    def explain(soql)
      response = api_get("/query/", {"explain" => soql})
      raise_on_error(response)
      JSON.parse(response.body)
    end

    def search(sosl)
      response = api_get("/search/", {"q" => sosl})
      raise_on_error(response)
      JSON.parse(response.body)
    end

    # CRUD

    def find(sobject : String, id : String, field : String? = nil)
      path = if field
               "/sobjects/#{sobject}/#{field}/#{URI.encode_path(id)}"
             else
               "/sobjects/#{sobject}/#{id}"
             end
      response = api_get(path)
      raise_on_error(response)
      JSON.parse(response.body)
    end

    def select(sobject : String, id : String, select_fields : Array(String), field : String? = nil)
      path = if field
               "/sobjects/#{sobject}/#{field}/#{URI.encode_path(id)}"
             else
               "/sobjects/#{sobject}/#{id}"
             end
      response = api_get(path, {"fields" => select_fields.join(",")})
      raise_on_error(response)
      JSON.parse(response.body)
    end

    def create(sobject, attrs)
      response = api_post("/sobjects/#{sobject}/", attrs)
      response
    end

    def update(sobject, id, attrs)
      response = api_patch("/sobjects/#{sobject}/#{id}", attrs)
      response
    end

    def upsert(sobject, field, attrs)
      external_id = attrs.fetch(attrs.keys.find { |k| k.to_s.downcase == field.to_s.downcase }, nil)
      attrs_without_field = attrs.reject { |k, v| k.to_s.downcase == field.to_s.downcase }
      response = api_patch(
        "/sobjects/#{sobject}/#{field}/#{URI.encode_path(external_id.not_nil!.to_s)}",
        attrs_without_field
      )
      if response.body.empty?
        true
      else
        parsed = JSON.parse(response.body)
        parsed["id"]? || true
      end
    end

    def destroy(sobject, id)
      api_delete("/sobjects/#{sobject}/#{id}")
    end

    # Describe / Metadata

    def describe(sobject : String? = nil)
      path = if sobject
               "/sobjects/#{sobject}/describe"
             else
               "/sobjects"
             end
      response = api_get(path)
      raise_on_error(response)
      JSON.parse(response.body)
    end

    def describe_layouts(sobject : String, layout_id : String? = nil)
      path = if layout_id
               "/sobjects/#{sobject}/describe/layouts/#{layout_id}"
             else
               "/sobjects/#{sobject}/describe/layouts"
             end
      response = api_get(path)
      raise_on_error(response)
      JSON.parse(response.body)
    end

    def list_sobjects
      result = describe
      result["sobjects"].as_a.map { |s| s["name"].as_s }
    end

    # Org info

    def limits
      response = api_get("/limits")
      raise_on_error(response)
      JSON.parse(response.body)
    end

    def user_info
      response = with_retry do
        HTTP::Client.get "#{@instance_url}/services/oauth2/userinfo",
          headers: auth_headers
      end
      raise_on_error(response)
      JSON.parse(response.body)
    end

    def org_id
      result = query("SELECT Id FROM Organization")
      result[0]["Id"].as_s
    end

    # Change tracking

    def get_updated(sobject : String, start_time : Time, end_time : Time)
      params = {
        "start" => start_time.to_utc.to_rfc3339,
        "end"   => end_time.to_utc.to_rfc3339,
      }
      response = api_get("/sobjects/#{sobject}/updated/", params)
      raise_on_error(response)
      JSON.parse(response.body)
    end

    def get_deleted(sobject : String, start_time : Time, end_time : Time)
      params = {
        "start" => start_time.to_utc.to_rfc3339,
        "end"   => end_time.to_utc.to_rfc3339,
      }
      response = api_get("/sobjects/#{sobject}/deleted/", params)
      raise_on_error(response)
      JSON.parse(response.body)
    end

    # Recent

    def recent(limit : Int32? = nil)
      params = limit ? {"limit" => limit.to_s} : nil
      response = api_get("/recent", params)
      raise_on_error(response)
      JSON.parse(response.body)
    end

    # Picklist values

    def picklist_values(sobject : String, field : String, valid_for : String? = nil)
      desc = describe(sobject)
      fields = desc["fields"].as_a
      target_field = fields.find { |f| f["name"].as_s.downcase == field.downcase }
      raise ServerError.new("Field '#{field}' not found on #{sobject}") unless target_field

      picklist_entries = target_field["picklistValues"].as_a

      if valid_for
        # Dependent picklist filtering
        unless target_field["dependentPicklist"]?.try(&.as_bool)
          raise ServerError.new("'#{field}' is not a dependent picklist")
        end

        controlling_field_name = target_field["controllerName"]?.try(&.as_s)
        raise ServerError.new("No controlling field found for '#{field}'") unless controlling_field_name

        controlling_field = fields.find { |f| f["name"].as_s.downcase == controlling_field_name.downcase }
        raise ServerError.new("Controlling field '#{controlling_field_name}' not found") unless controlling_field

        controlling_values = controlling_field["picklistValues"].as_a
        controlling_index = controlling_values.index { |v| v["value"].as_s == valid_for }
        raise ServerError.new("Value '#{valid_for}' not found in controlling field") unless controlling_index

        picklist_entries.select do |entry|
          valid_for_bytes = entry["validFor"]?.try(&.as_s)
          next false unless valid_for_bytes
          decoded = Base64.decode(valid_for_bytes)
          byte_index = controlling_index >> 3
          bit_index = controlling_index % 8
          byte_index < decoded.size && (decoded[byte_index] & (0x80 >> bit_index)) != 0
        end
      else
        picklist_entries
      end
    end

    # Batch API

    def batch(halt_on_error : Bool = false, &)
      subrequests = BatchSubrequests.new(@api_version)
      yield subrequests
      results = [] of JSON::Any
      subrequests.each_chunk(25) do |chunk|
        body = {
          "haltOnError"  => halt_on_error,
          "batchRequests" => chunk,
        }
        response = api_post("/composite/batch", body)
        raise_on_error(response)
        parsed = JSON.parse(response.body)
        if halt_on_error && parsed["hasErrors"]?.try(&.as_bool)
          raise ServerError.new("Batch API returned errors")
        end
        parsed["results"].as_a.each { |r| results << r }
      end
      results
    end

    # Composite API

    def composite(all_or_none : Bool = false, collate_subrequests : Bool = false, &)
      subrequests = CompositeSubrequests.new(@api_version)
      yield subrequests
      body = {
        "allOrNone"          => all_or_none,
        "collateSubrequests" => collate_subrequests,
        "compositeRequest"   => subrequests.to_a,
      }
      response = api_post("/composite", body)
      raise_on_error(response)
      parsed = JSON.parse(response.body)
      if all_or_none
        parsed["compositeResponse"].as_a.each do |r|
          status = r["httpStatusCode"].as_i
          if status >= 400
            raise ServerError.new("Composite API returned error: #{r["body"]}")
          end
        end
      end
      parsed["compositeResponse"]
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

    private def raise_on_error(response)
      return if response.status_code >= 200 && response.status_code < 300
      body = JSON.parse(response.body) rescue nil
      message = if body && body[0]?
                   body[0]["message"]?.try(&.as_s) || "Salesforce API error"
                 elsif body && body["error_description"]?
                   body["error_description"].as_s
                 else
                   "Salesforce API error (#{response.status_code})"
                 end
      case response.status_code
      when 401
        raise UnauthorizedError.new(message)
      when 404
        raise ServerError.new(message)
      else
        raise ServerError.new(message)
      end
    end
  end

  # Batch API subrequests builder
  class BatchSubrequests
    def initialize(@api_version : String)
      @requests = [] of JSON::Any
    end

    def create(sobject : String, attrs)
      @requests << JSON.parse({
        "method"    => "POST",
        "url"       => "v#{@api_version}/sobjects/#{sobject}",
        "richInput" => attrs,
      }.to_json)
    end

    def update(sobject : String, id : String, attrs)
      @requests << JSON.parse({
        "method"    => "PATCH",
        "url"       => "v#{@api_version}/sobjects/#{sobject}/#{id}",
        "richInput" => attrs,
      }.to_json)
    end

    def destroy(sobject : String, id : String)
      @requests << JSON.parse({
        "method" => "DELETE",
        "url"    => "v#{@api_version}/sobjects/#{sobject}/#{id}",
      }.to_json)
    end

    def upsert(sobject : String, field : String, attrs)
      external_id = attrs.fetch(attrs.keys.find { |k| k.to_s.downcase == field.to_s.downcase }, nil)
      attrs_without_field = attrs.reject { |k, v| k.to_s.downcase == field.to_s.downcase }
      @requests << JSON.parse({
        "method"    => "PATCH",
        "url"       => "v#{@api_version}/sobjects/#{sobject}/#{field}/#{URI.encode_path(external_id.not_nil!.to_s)}",
        "richInput" => attrs_without_field,
      }.to_json)
    end

    def each_chunk(size, &)
      @requests.each_slice(size) { |chunk| yield chunk }
    end
  end

  # Composite API subrequests builder
  class CompositeSubrequests
    def initialize(@api_version : String)
      @requests = [] of JSON::Any
    end

    def create(sobject : String, reference_id : String, attrs)
      @requests << JSON.parse({
        "method"      => "POST",
        "url"         => "/services/data/v#{@api_version}/sobjects/#{sobject}",
        "referenceId" => reference_id,
        "body"        => attrs,
      }.to_json)
    end

    def update(sobject : String, reference_id : String, id : String, attrs)
      @requests << JSON.parse({
        "method"      => "PATCH",
        "url"         => "/services/data/v#{@api_version}/sobjects/#{sobject}/#{id}",
        "referenceId" => reference_id,
        "body"        => attrs,
      }.to_json)
    end

    def destroy(sobject : String, reference_id : String, id : String)
      @requests << JSON.parse({
        "method"      => "DELETE",
        "url"         => "/services/data/v#{@api_version}/sobjects/#{sobject}/#{id}",
        "referenceId" => reference_id,
      }.to_json)
    end

    def find(sobject : String, reference_id : String, id : String)
      @requests << JSON.parse({
        "method"      => "GET",
        "url"         => "/services/data/v#{@api_version}/sobjects/#{sobject}/#{id}",
        "referenceId" => reference_id,
      }.to_json)
    end

    def upsert(sobject : String, reference_id : String, field : String, attrs)
      external_id = attrs.fetch(attrs.keys.find { |k| k.to_s.downcase == field.to_s.downcase }, nil)
      attrs_without_field = attrs.reject { |k, v| k.to_s.downcase == field.to_s.downcase }
      @requests << JSON.parse({
        "method"      => "PATCH",
        "url"         => "/services/data/v#{@api_version}/sobjects/#{sobject}/#{field}/#{URI.encode_path(external_id.not_nil!.to_s)}",
        "referenceId" => reference_id,
        "body"        => attrs_without_field,
      }.to_json)
    end

    def to_a
      @requests
    end
  end
end
