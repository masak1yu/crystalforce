require "./spec_helper"

describe "Error handling" do
  describe "error class hierarchy" do
    it "Error is a subclass of Exception" do
      Crystalforce::Error.new("test").should be_a(Exception)
    end

    it "ServerError is a subclass of Error" do
      Crystalforce::ServerError.new("test").should be_a(Crystalforce::Error)
    end

    it "AuthenticationError is a subclass of Error" do
      Crystalforce::AuthenticationError.new("test").should be_a(Crystalforce::Error)
    end

    it "UnauthorizedError is a subclass of Error" do
      Crystalforce::UnauthorizedError.new("test").should be_a(Crystalforce::Error)
    end

    it "NotFoundError is a subclass of Error" do
      Crystalforce::NotFoundError.new("test").should be_a(Crystalforce::Error)
    end

    it "APIVersionError is a subclass of Error" do
      Crystalforce::APIVersionError.new("test").should be_a(Crystalforce::Error)
    end
  end

  describe "raise_on_error" do
    it "raises NotFoundError on 404" do
      stub_api_request(:get, "sobjects/Account/bad_id", nil, status: 404, body: fixture("sobject/sobject_find_error_response"))
      client = build_client
      expect_raises(Crystalforce::NotFoundError) do
        client.find("Account", "bad_id")
      end
    end

    it "raises UnauthorizedError on 401" do
      body = %([{"message":"Session expired","errorCode":"INVALID_SESSION_ID"}])
      # Need to exhaust retries first - use 0 retries
      stub_auth_request
      WebMock.stub(:get, /sobjects\/Account\/test/)
        .to_return(status: 401, body: body)

      client = build_client(authentication_retries: 0)
      expect_raises(Crystalforce::UnauthorizedError) do
        client.find("Account", "test")
      end
    end

    it "raises ServerError on 400 with error message" do
      stub_api_request(:post, "sobjects/Account/", nil, status: 400, body: fixture("sobject/write_error_response"))
      client = build_client
      expect_raises(Crystalforce::ServerError, /No such column/) do
        client.create!("Account", {"foo" => "bar"})
      end
    end

    it "raises ServerError on 300 (multiple records)" do
      body = %(["/services/data/v23.0/sobjects/Whizbang/foo","/services/data/v23.0/sobjects/Whizbang/bar"])
      stub_api_request(:get, "sobjects/Whizbang/External__c/dup", nil, status: 300, body: body)
      client = build_client
      expect_raises(Crystalforce::ServerError, /Multiple records/) do
        client.find("Whizbang", "dup", field: "External__c")
      end
    end

    it "raises ServerError on 413" do
      body = %([{"message":"Request too large","errorCode":"REQUEST_LIMIT_EXCEEDED"}])
      stub_api_request(:post, "sobjects/Account/", nil, status: 413, body: body)
      client = build_client
      expect_raises(Crystalforce::ServerError, /too large/) do
        client.create!("Account", {"data" => "x" * 10000})
      end
    end
  end
end
