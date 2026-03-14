require "http/client"
require "json"

module Crystalforce
  class StreamingClient
    def initialize(
      @instance_url : String,
      @access_token : String,
      @api_version : String = "58.0"
    )
      @client_id = ""
      @running = false
    end

    # Subscribe to channels and yield messages
    def subscribe(channels : Array(String), replay : Hash(String, Int64)? = nil, &block : JSON::Any ->)
      handshake
      channels.each { |ch| do_subscribe(ch, replay) }
      @running = true
      while @running
        messages = do_connect
        messages.each do |msg|
          channel = msg["channel"]?.try(&.as_s)
          next unless channel
          next if channel.starts_with?("/meta/")
          block.call(msg)
        end
      end
    end

    # Subscribe to a single channel
    def subscribe(channel : String, replay_id : Int64 = -1, &block : JSON::Any ->)
      subscribe([channel], {channel => replay_id}, &block)
    end

    def disconnect
      @running = false
      return if @client_id.empty?
      body = JSON.build do |json|
        json.array do
          json.object do
            json.field "channel", "/meta/disconnect"
            json.field "clientId", @client_id
          end
        end
      end
      post(body)
    end

    private def cometd_url
      "#{@instance_url}/cometd/#{@api_version}"
    end

    private def handshake
      body = JSON.build do |json|
        json.array do
          json.object do
            json.field "channel", "/meta/handshake"
            json.field "version", "1.0"
            json.field "minimumVersion", "1.0"
            json.field "supportedConnectionTypes" do
              json.array { json.string "long-polling" }
            end
          end
        end
      end
      response = post(body)
      msg = response[0]
      unless msg["successful"]?.try(&.as_bool)
        raise ServerError.new("CometD handshake failed: #{msg}")
      end
      @client_id = msg["clientId"].as_s
    end

    private def do_subscribe(channel : String, replay : Hash(String, Int64)? = nil)
      body = JSON.build do |json|
        json.array do
          json.object do
            json.field "channel", "/meta/subscribe"
            json.field "clientId", @client_id
            json.field "subscription", channel
            if replay
              replay_id = replay[channel]? || -1_i64
              json.field "ext" do
                json.object do
                  json.field "replay" do
                    json.object do
                      json.field channel, replay_id
                    end
                  end
                end
              end
            end
          end
        end
      end
      response = post(body)
      msg = response[0]
      unless msg["successful"]?.try(&.as_bool)
        raise ServerError.new("CometD subscribe failed for #{channel}: #{msg}")
      end
    end

    private def do_connect : Array(JSON::Any)
      body = JSON.build do |json|
        json.array do
          json.object do
            json.field "channel", "/meta/connect"
            json.field "clientId", @client_id
            json.field "connectionType", "long-polling"
          end
        end
      end
      post(body)
    end

    private def post(body : String) : Array(JSON::Any)
      response = HTTP::Client.post(
        cometd_url,
        headers: HTTP::Headers{
          "Authorization" => "Bearer #{@access_token}",
          "Content-Type"  => "application/json",
        },
        body: body
      )
      unless response.status_code == 200
        raise ServerError.new("CometD request failed (#{response.status_code}): #{response.body}")
      end
      JSON.parse(response.body).as_a
    end
  end

  class Client
    def streaming(api_version : String? = nil)
      StreamingClient.new(
        instance_url: @instance_url,
        access_token: @access_token,
        api_version: api_version || @api_version,
      )
    end
  end

  class ToolingClient
    def streaming(api_version : String? = nil)
      StreamingClient.new(
        instance_url: @instance_url,
        access_token: @access_token,
        api_version: api_version || @api_version,
      )
    end
  end
end
