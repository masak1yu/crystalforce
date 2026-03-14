require "./spec_helper"

describe "Crystalforce config" do
  describe "environment variable loading" do
    it "reads SALESFORCE_USERNAME" do
      ENV["SALESFORCE_USERNAME"] = "env_user"
      Crystalforce.env_username.should eq("env_user")
      ENV.delete("SALESFORCE_USERNAME")
    end

    it "reads SALESFORCE_PASSWORD" do
      ENV["SALESFORCE_PASSWORD"] = "env_pass"
      Crystalforce.env_password.should eq("env_pass")
      ENV.delete("SALESFORCE_PASSWORD")
    end

    it "reads SALESFORCE_SECURITY_TOKEN" do
      ENV["SALESFORCE_SECURITY_TOKEN"] = "env_token"
      Crystalforce.env_security_token.should eq("env_token")
      ENV.delete("SALESFORCE_SECURITY_TOKEN")
    end

    it "reads SALESFORCE_CLIENT_ID" do
      ENV["SALESFORCE_CLIENT_ID"] = "env_cid"
      Crystalforce.env_client_id.should eq("env_cid")
      ENV.delete("SALESFORCE_CLIENT_ID")
    end

    it "reads SALESFORCE_CLIENT_SECRET" do
      ENV["SALESFORCE_CLIENT_SECRET"] = "env_cs"
      Crystalforce.env_client_secret.should eq("env_cs")
      ENV.delete("SALESFORCE_CLIENT_SECRET")
    end

    it "reads SALESFORCE_HOST" do
      ENV["SALESFORCE_HOST"] = "test.salesforce.com"
      Crystalforce.env_host.should eq("test.salesforce.com")
      ENV.delete("SALESFORCE_HOST")
    end

    it "reads SALESFORCE_API_VERSION" do
      ENV["SALESFORCE_API_VERSION"] = "58.0"
      Crystalforce.env_api_version.should eq("58.0")
      ENV.delete("SALESFORCE_API_VERSION")
    end

    it "reads SALESFORCE_PROXY_URI" do
      ENV["SALESFORCE_PROXY_URI"] = "http://proxy:8080"
      Crystalforce.env_proxy_uri.should eq("http://proxy:8080")
      ENV.delete("SALESFORCE_PROXY_URI")
    end

    it "returns nil when environment variable is not set" do
      ENV.delete("SALESFORCE_USERNAME")
      Crystalforce.env_username.should be_nil
    end
  end

  describe "defaults" do
    it "uses login.salesforce.com as default host" do
      client = build_client
      # The auth request was stubbed for login.salesforce.com
      client.instance_url.should eq("https://na1.salesforce.com")
    end

    it "uses 34.0 as default api_version" do
      stub_api_request(:get, "sobjects", "describe_sobjects_success_response")
      client = build_client
      # If API version is wrong, the stub won't match and the test will fail
      client.describe
    end
  end
end
