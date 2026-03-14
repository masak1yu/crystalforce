require "./spec_helper"

describe "Gzip compression" do
  it "sends Accept-Encoding header when compress is true" do
    stub_auth_request
    request_headers = nil
    WebMock.stub(:get, /limits/)
      .to_return do |request|
        request_headers = request.headers.dup
        HTTP::Client::Response.new(200, body: fixture("sobject/limits_success_response"))
      end

    client = build_client(compress: true)
    client.limits
    request_headers.not_nil!["Accept-Encoding"].should eq("gzip")
  end

  it "decompresses gzipped responses" do
    stub_auth_request
    original_body = fixture("sobject/limits_success_response")

    # Gzip the body
    io = IO::Memory.new
    Compress::Gzip::Writer.open(io) { |gz| gz.print(original_body) }
    gzipped = io.to_s

    WebMock.stub(:get, /limits/)
      .to_return(status: 200, body: gzipped, headers: {"Content-Encoding" => "gzip", "Content-Type" => "application/json"})

    client = build_client(compress: true)
    result = client.limits
    result["DailyApiRequests"]["Max"].as_i.should eq(15000)
  end

  it "does not send Accept-Encoding when compress is false" do
    stub_auth_request
    request_headers = nil
    WebMock.stub(:get, /limits/)
      .to_return do |request|
        request_headers = request.headers.dup
        HTTP::Client::Response.new(200, body: fixture("sobject/limits_success_response"))
      end

    client = build_client(compress: false)
    client.limits
    request_headers.not_nil!["Accept-Encoding"]?.should be_nil
  end
end
