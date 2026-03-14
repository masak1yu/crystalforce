require "./spec_helper"

describe Crystalforce::ToolingClient do
  describe "#initialize" do
    it "authenticates on creation" do
      stub_auth_request
      client = Crystalforce::ToolingClient.new(
        username: "user@example.com",
        password: "password",
        security_token: "token",
        client_id: "client_id",
        client_secret: "client_secret",
      )
      client.access_token.should_not be_empty
      client.instance_url.should eq("https://na1.salesforce.com")
    end

    it "invokes authentication_callback" do
      stub_auth_request
      callback_called = false
      callback = ->(c : Crystalforce::ToolingClient) {
        callback_called = true
        nil
      }
      Crystalforce::ToolingClient.new(
        username: "user@example.com",
        password: "password",
        security_token: "token",
        client_id: "client_id",
        client_secret: "client_secret",
        authentication_callback: callback,
      )
      callback_called.should be_true
    end
  end

  describe "API calls use tooling path" do
    it "uses /tooling in the API path" do
      stub_auth_request
      WebMock.stub(:get, "https://na1.salesforce.com/services/data/v34.0/tooling/query/?q=SELECT+Id+FROM+ApexClass")
        .to_return(status: 200, body: fixture("sobject/query_success_response"))

      client = Crystalforce::ToolingClient.new(
        username: "user@example.com",
        password: "password",
        security_token: "token",
        client_id: "client_id",
        client_secret: "client_secret",
      )
      records = client.query("SELECT Id FROM ApexClass")
      records.as_a.size.should eq(1)
    end
  end
end
