require "./spec_helper"

describe "Composite API" do
  describe "#composite" do
    it "executes composite subrequests" do
      stub_api_request(:post, "composite", "composite_success_response")
      client = build_client
      results = client.composite do |comp|
        comp.create("Account", "ref1", {"Name" => "Test"})
        comp.update("Account", "ref2", "001", {"Name" => "Updated"})
      end
      results.as_a.size.should eq(2)
      results[0]["referenceId"].as_s.should eq("ref1")
    end

    it "supports all_or_none" do
      error_body = %({"compositeResponse":[{"body":[{"message":"error","errorCode":"INVALID"}],"httpHeaders":{},"httpStatusCode":400,"referenceId":"ref1"}]})
      stub_api_request(:post, "composite", nil, body: error_body)
      client = build_client
      expect_raises(Crystalforce::ServerError, /Composite API returned error/) do
        client.composite(all_or_none: true) do |comp|
          comp.create("Account", "ref1", {"Name" => "Test"})
        end
      end
    end
  end

  describe Crystalforce::CompositeSubrequests do
    it "builds create subrequests" do
      sub = Crystalforce::CompositeSubrequests.new("34.0")
      sub.create("Account", "ref1", {"Name" => "Test"})
      requests = sub.to_a
      requests.size.should eq(1)
      requests[0]["method"].as_s.should eq("POST")
      requests[0]["referenceId"].as_s.should eq("ref1")
      requests[0]["url"].as_s.should contain("sobjects/Account")
    end

    it "builds update subrequests" do
      sub = Crystalforce::CompositeSubrequests.new("34.0")
      sub.update("Account", "ref1", "001", {"Name" => "Updated"})
      requests = sub.to_a
      requests[0]["method"].as_s.should eq("PATCH")
      requests[0]["url"].as_s.should contain("Account/001")
    end

    it "builds destroy subrequests" do
      sub = Crystalforce::CompositeSubrequests.new("34.0")
      sub.destroy("Account", "ref1", "001")
      requests = sub.to_a
      requests[0]["method"].as_s.should eq("DELETE")
    end

    it "builds find subrequests" do
      sub = Crystalforce::CompositeSubrequests.new("34.0")
      sub.find("Account", "ref1", "001")
      requests = sub.to_a
      requests[0]["method"].as_s.should eq("GET")
    end

    it "builds upsert subrequests" do
      sub = Crystalforce::CompositeSubrequests.new("34.0")
      sub.upsert("Account", "ref1", "External__c", {"External__c" => "123", "Name" => "Test"})
      requests = sub.to_a
      requests[0]["method"].as_s.should eq("PATCH")
      requests[0]["url"].as_s.should contain("External__c/123")
    end
  end
end
