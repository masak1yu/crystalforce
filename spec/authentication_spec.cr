require "./spec_helper"

describe Crystalforce::Authentication do
  describe ".authenticate" do
    describe "password authentication" do
      it "authenticates with username, password, and security_token" do
        WebMock.stub(:post, "https://login.salesforce.com/services/oauth2/token")
          .to_return(status: 200, body: auth_success_body)

        response = Crystalforce::Authentication.authenticate(
          username: "user@example.com",
          password: "password",
          security_token: "token",
          client_id: "client_id",
          client_secret: "client_secret",
        )

        response.should_not be_nil
        response.not_nil!.status_code.should eq(200)
        body = JSON.parse(response.not_nil!.body)
        body["access_token"].as_s.should_not be_empty
      end

      it "concatenates password and security_token in form body" do
        captured_body = ""
        WebMock.stub(:post, "https://login.salesforce.com/services/oauth2/token")
          .to_return do |request|
            captured_body = request.body.try(&.gets_to_end) || ""
            HTTP::Client::Response.new(200, body: auth_success_body)
          end

        Crystalforce::Authentication.authenticate(
          username: "user@example.com",
          password: "password",
          security_token: "token",
          client_id: "client_id",
          client_secret: "client_secret",
        )

        captured_body.should contain("password=passwordtoken")
      end

      it "sends grant_type=password" do
        captured_body = ""
        WebMock.stub(:post, "https://login.salesforce.com/services/oauth2/token")
          .to_return do |request|
            captured_body = request.body.try(&.gets_to_end) || ""
            HTTP::Client::Response.new(200, body: auth_success_body)
          end

        Crystalforce::Authentication.authenticate(
          username: "user@example.com",
          password: "password",
          security_token: "token",
          client_id: "client_id",
          client_secret: "client_secret",
        )

        captured_body.should contain("grant_type=password")
      end

      it "returns error response on failure" do
        WebMock.stub(:post, "https://login.salesforce.com/services/oauth2/token")
          .to_return(status: 400, body: fixture("auth_error_response"))

        response = Crystalforce::Authentication.authenticate(
          username: "user@example.com",
          password: "bad_password",
          security_token: "token",
          client_id: "client_id",
          client_secret: "client_secret",
        )

        response.not_nil!.status_code.should eq(400)
      end
    end

    describe "refresh token authentication" do
      it "authenticates with refresh_token" do
        WebMock.stub(:post, "https://login.salesforce.com/services/oauth2/token")
          .to_return(status: 200, body: fixture("refresh_success_response"))

        response = Crystalforce::Authentication.authenticate(
          refresh_token: "refresh_token",
          client_id: "client_id",
          client_secret: "client_secret",
        )

        response.should_not be_nil
        body = JSON.parse(response.not_nil!.body)
        body["access_token"].as_s.should eq("refreshed_access_token")
      end

      it "sends grant_type=refresh_token" do
        captured_body = ""
        WebMock.stub(:post, "https://login.salesforce.com/services/oauth2/token")
          .to_return do |request|
            captured_body = request.body.try(&.gets_to_end) || ""
            HTTP::Client::Response.new(200, body: fixture("refresh_success_response"))
          end

        Crystalforce::Authentication.authenticate(
          refresh_token: "refresh_token",
          client_id: "client_id",
          client_secret: "client_secret",
        )

        captured_body.should contain("grant_type=refresh_token")
      end

      it "returns error on expired refresh token" do
        WebMock.stub(:post, "https://login.salesforce.com/services/oauth2/token")
          .to_return(status: 400, body: fixture("refresh_error_response"))

        response = Crystalforce::Authentication.authenticate(
          refresh_token: "expired_token",
          client_id: "client_id",
          client_secret: "client_secret",
        )

        response.not_nil!.status_code.should eq(400)
      end
    end

    describe "JWT bearer authentication" do
      it "authenticates with jwt_key" do
        WebMock.stub(:post, "https://login.salesforce.com/services/oauth2/token")
          .to_return(status: 200, body: auth_success_body)

        jwt_key = File.read(File.join(FIXTURE_PATH, "test_private.key"))
        response = Crystalforce::Authentication.authenticate(
          jwt_key: jwt_key,
          client_id: "client_id",
          username: "user@example.com",
        )

        response.should_not be_nil
        response.not_nil!.status_code.should eq(200)
      end

      it "sends grant_type for jwt-bearer" do
        captured_body = ""
        WebMock.stub(:post, "https://login.salesforce.com/services/oauth2/token")
          .to_return do |request|
            captured_body = request.body.try(&.gets_to_end) || ""
            HTTP::Client::Response.new(200, body: auth_success_body)
          end

        jwt_key = File.read(File.join(FIXTURE_PATH, "test_private.key"))
        Crystalforce::Authentication.authenticate(
          jwt_key: jwt_key,
          client_id: "client_id",
          username: "user@example.com",
        )

        captured_body.should contain("grant_type=urn")
        captured_body.should contain("jwt-bearer")
      end
    end

    describe "client credentials authentication" do
      it "authenticates with client_id and client_secret only" do
        WebMock.stub(:post, "https://login.salesforce.com/services/oauth2/token")
          .to_return(status: 200, body: auth_success_body)

        response = Crystalforce::Authentication.authenticate(
          client_id: "client_id",
          client_secret: "client_secret",
        )

        response.should_not be_nil
        response.not_nil!.status_code.should eq(200)
      end

      it "sends grant_type=client_credentials" do
        captured_body = ""
        WebMock.stub(:post, "https://login.salesforce.com/services/oauth2/token")
          .to_return do |request|
            captured_body = request.body.try(&.gets_to_end) || ""
            HTTP::Client::Response.new(200, body: auth_success_body)
          end

        Crystalforce::Authentication.authenticate(
          client_id: "client_id",
          client_secret: "client_secret",
        )

        captured_body.should contain("grant_type=client_credentials")
      end
    end

    describe "authentication dispatch" do
      it "returns nil when no valid credentials are provided" do
        response = Crystalforce::Authentication.authenticate
        response.should be_nil
      end

      it "prefers JWT when jwt_key, client_id, and username are all provided" do
        captured_body = ""
        WebMock.stub(:post, "https://login.salesforce.com/services/oauth2/token")
          .to_return do |request|
            captured_body = request.body.try(&.gets_to_end) || ""
            HTTP::Client::Response.new(200, body: auth_success_body)
          end

        jwt_key = File.read(File.join(FIXTURE_PATH, "test_private.key"))
        Crystalforce::Authentication.authenticate(
          jwt_key: jwt_key,
          client_id: "client_id",
          client_secret: "client_secret",
          username: "user@example.com",
          password: "password",
        )

        captured_body.should contain("grant_type=urn")
      end

      it "uses custom host" do
        WebMock.stub(:post, "https://test.salesforce.com/services/oauth2/token")
          .to_return(status: 200, body: auth_success_body)

        response = Crystalforce::Authentication.authenticate(
          client_id: "client_id",
          client_secret: "client_secret",
          host: "test.salesforce.com",
        )

        response.should_not be_nil
      end
    end
  end
end
