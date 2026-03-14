require "./spec_helper"

describe "Batch API" do
  describe "#batch" do
    it "executes batch subrequests" do
      stub_api_request(:post, "composite/batch", "batch_success_response")
      client = build_client
      results = client.batch do |batch|
        batch.create("Account", {"Name" => "Test"})
        batch.update("Account", "001", {"Name" => "Updated"})
      end
      results.size.should eq(2)
      results[0]["statusCode"].as_i.should eq(201)
    end

    it "chunks requests into groups of 25" do
      # Stub two batch calls (26 requests = 25 + 1)
      call_count = 0
      WebMock.stub(:post, /composite\/batch/)
        .to_return do |request|
          call_count += 1
          HTTP::Client::Response.new(200, body: fixture("sobject/batch_success_response"))
        end

      client = build_client
      results = client.batch do |batch|
        26.times { |i| batch.create("Account", {"Name" => "Test#{i}"}) }
      end
      call_count.should eq(2)
    end

    it "supports halt_on_error" do
      error_body = %({"hasErrors":true,"results":[{"statusCode":400,"result":[{"message":"error","errorCode":"INVALID"}]}]})
      stub_api_request(:post, "composite/batch", nil, body: error_body)
      client = build_client
      expect_raises(Crystalforce::ServerError, /Batch API returned errors/) do
        client.batch(halt_on_error: true) do |batch|
          batch.create("Account", {"Name" => "Test"})
        end
      end
    end
  end

  describe Crystalforce::BatchSubrequests do
    it "builds create subrequests" do
      sub = Crystalforce::BatchSubrequests.new("34.0")
      sub.create("Account", {"Name" => "Test"})
      chunks = [] of Array(JSON::Any)
      sub.each_chunk(25) { |c| chunks << c }
      chunks.size.should eq(1)
      chunks[0][0]["method"].as_s.should eq("POST")
      chunks[0][0]["url"].as_s.should eq("v34.0/sobjects/Account")
    end

    it "builds update subrequests" do
      sub = Crystalforce::BatchSubrequests.new("34.0")
      sub.update("Account", "001", {"Name" => "Updated"})
      chunks = [] of Array(JSON::Any)
      sub.each_chunk(25) { |c| chunks << c }
      chunks[0][0]["method"].as_s.should eq("PATCH")
      chunks[0][0]["url"].as_s.should contain("Account/001")
    end

    it "builds destroy subrequests" do
      sub = Crystalforce::BatchSubrequests.new("34.0")
      sub.destroy("Account", "001")
      chunks = [] of Array(JSON::Any)
      sub.each_chunk(25) { |c| chunks << c }
      chunks[0][0]["method"].as_s.should eq("DELETE")
    end

    it "builds upsert subrequests" do
      sub = Crystalforce::BatchSubrequests.new("34.0")
      sub.upsert("Account", "External__c", {"External__c" => "123", "Name" => "Test"})
      chunks = [] of Array(JSON::Any)
      sub.each_chunk(25) { |c| chunks << c }
      chunks[0][0]["method"].as_s.should eq("PATCH")
      chunks[0][0]["url"].as_s.should contain("External__c/123")
    end
  end
end
