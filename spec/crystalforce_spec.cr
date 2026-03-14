require "./spec_helper"

describe Crystalforce do
  describe ".new" do
    it "returns a Client instance" do
      stub_auth_request
      client = Crystalforce.new(
        username: "user@example.com",
        password: "password",
        security_token: "token",
        client_id: "client_id",
        client_secret: "client_secret",
      )
      client.should be_a(Crystalforce::Client)
    end
  end

  describe ".tooling" do
    it "returns a ToolingClient instance" do
      stub_auth_request
      client = Crystalforce.tooling(
        username: "user@example.com",
        password: "password",
        security_token: "token",
        client_id: "client_id",
        client_secret: "client_secret",
      )
      client.should be_a(Crystalforce::ToolingClient)
    end
  end
end
