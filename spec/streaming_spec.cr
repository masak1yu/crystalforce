require "./spec_helper"

describe Crystalforce::StreamingClient do
  describe "#initialize" do
    it "creates a streaming client" do
      client = Crystalforce::StreamingClient.new(
        instance_url: "https://na1.salesforce.com",
        access_token: "token123",
      )
      client.should be_a(Crystalforce::StreamingClient)
    end

    it "accepts custom api_version" do
      client = Crystalforce::StreamingClient.new(
        instance_url: "https://na1.salesforce.com",
        access_token: "token123",
        api_version: "50.0",
      )
      client.should be_a(Crystalforce::StreamingClient)
    end
  end

  describe "#disconnect" do
    it "can be called without prior connection" do
      client = Crystalforce::StreamingClient.new(
        instance_url: "https://na1.salesforce.com",
        access_token: "token123",
      )
      # Should not raise - client_id is empty so it returns early
      client.disconnect
    end
  end

  describe "Client#streaming" do
    it "returns a StreamingClient" do
      client = build_client
      streaming = client.streaming
      streaming.should be_a(Crystalforce::StreamingClient)
    end

    it "passes custom api_version" do
      client = build_client
      streaming = client.streaming(api_version: "50.0")
      streaming.should be_a(Crystalforce::StreamingClient)
    end
  end
end
