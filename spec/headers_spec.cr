require "./spec_helper"

describe "Custom headers" do
  it "includes Authorization header with Bearer token" do
    stub_auth_request
    captured_headers = nil
    WebMock.stub(:get, /limits/)
      .to_return do |request|
        captured_headers = request.headers.dup
        HTTP::Client::Response.new(200, body: fixture("sobject/limits_success_response"))
      end

    client = build_client
    client.limits
    auth = captured_headers.not_nil!["Authorization"]
    auth.should start_with("Bearer ")
    auth.should contain("00Dx0000000BV7z")
  end

  it "includes custom request headers" do
    stub_auth_request
    captured_headers = nil
    WebMock.stub(:get, /limits/)
      .to_return do |request|
        captured_headers = request.headers.dup
        HTTP::Client::Response.new(200, body: fixture("sobject/limits_success_response"))
      end

    custom = {"X-Custom-Header" => "custom_value", "X-Another" => "another_value"}
    client = build_client(request_headers: custom)
    client.limits
    captured_headers.not_nil!["X-Custom-Header"].should eq("custom_value")
    captured_headers.not_nil!["X-Another"].should eq("another_value")
  end

  it "includes Content-Type for POST requests" do
    stub_auth_request
    captured_headers = nil
    WebMock.stub(:post, /sobjects\/Account/)
      .to_return do |request|
        captured_headers = request.headers.dup
        HTTP::Client::Response.new(201, body: fixture("sobject/create_success_response"))
      end

    client = build_client
    client.create("Account", {"Name" => "Test"})
    captured_headers.not_nil!["Content-Type"].should eq("application/json")
  end
end
