require "./spec_helper"

describe Crystalforce::Client do
  describe "#initialize" do
    it "authenticates on creation" do
      client = build_client
      client.access_token.should_not be_empty
      client.instance_url.should eq("https://na1.salesforce.com")
    end

    it "raises AuthenticationError on failed authentication" do
      WebMock.stub(:post, "https://login.salesforce.com/services/oauth2/token")
        .to_return(status: 400, body: fixture("auth_error_response"))

      expect_raises(Crystalforce::AuthenticationError, /Invalid Password/) do
        Crystalforce::Client.new(
          username: "user@example.com",
          password: "bad",
          security_token: "token",
          client_id: "client_id",
          client_secret: "client_secret",
        )
      end
    end

    it "raises AuthenticationError when no credentials provided" do
      expect_raises(Crystalforce::AuthenticationError, /No valid authentication/) do
        Crystalforce::Client.new
      end
    end

    it "uses default host" do
      client = build_client
      # Default host is login.salesforce.com (verified by stub_auth_request matching)
      client.instance_url.should_not be_empty
    end

    it "uses default api_version 34.0" do
      client = build_client
      # Verified by API calls using v34.0 in the URL
      stub_api_request(:get, "limits", "limits_success_response")
      client.limits
    end

    it "accepts custom api_version" do
      stub_api_request(:get, "limits", "limits_success_response", api_version: "58.0")
      client = build_client(api_version: "58.0")
      client.limits
    end

    it "invokes authentication_callback on successful auth" do
      callback_called = false
      callback_client = nil
      callback = ->(c : Crystalforce::Client) {
        callback_called = true
        callback_client = c
        nil
      }
      client = build_client(authentication_callback: callback)
      callback_called.should be_true
      callback_client.should eq(client)
    end
  end

  describe "#with_retry" do
    it "re-authenticates on 401 and retries" do
      client = build_client

      # First call returns 401, then stub auth again, then success
      call_count = 0
      WebMock.stub(:get, /limits/)
        .to_return do |request|
          call_count += 1
          if call_count == 1
            HTTP::Client::Response.new(401, body: %([{"message":"Session expired","errorCode":"INVALID_SESSION_ID"}]))
          else
            HTTP::Client::Response.new(200, body: fixture("sobject/limits_success_response"))
          end
        end

      # Re-auth stub (already stubbed from build_client, but let's be explicit)
      stub_auth_request

      result = client.limits
      result.should_not be_nil
      call_count.should eq(2)
    end
  end
end
