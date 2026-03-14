require "./spec_helper"

describe Crystalforce::Collection do
  describe "#query_with_pagination" do
    it "returns a Collection" do
      stub_api_request(:get, "query/?q=SELECT+Id+FROM+Account", "query_paginated_first_page_response")
      client = build_client
      collection = client.query_with_pagination("SELECT Id FROM Account")
      collection.should be_a(Crystalforce::Collection)
    end

    it "has correct total_size" do
      stub_api_request(:get, "query/?q=SELECT+Id+FROM+Account", "query_paginated_first_page_response")
      client = build_client
      collection = client.query_with_pagination("SELECT Id FROM Account")
      collection.total_size.should eq(2)
    end

    it "has current_page records" do
      stub_api_request(:get, "query/?q=SELECT+Id+FROM+Account", "query_paginated_first_page_response")
      client = build_client
      collection = client.query_with_pagination("SELECT Id FROM Account")
      collection.current_page.size.should eq(1)
      collection.current_page[0]["Text_Label"].as_s.should eq("First Page")
    end

    it "knows if there is a next page" do
      stub_api_request(:get, "query/?q=SELECT+Id+FROM+Account", "query_paginated_first_page_response")
      client = build_client
      collection = client.query_with_pagination("SELECT Id FROM Account")
      collection.has_next_page?.should be_true
      collection.done.should be_false
    end

    it "fetches next page" do
      stub_api_request(:get, "query/?q=SELECT+Id+FROM+Account", "query_paginated_first_page_response")
      stub_api_request(:get, "query/01gD", "query_paginated_last_page_response")
      client = build_client
      collection = client.query_with_pagination("SELECT Id FROM Account")
      next_page = collection.next_page
      next_page.should_not be_nil
      next_page.not_nil![0]["Text_Label"].as_s.should eq("Last Page")
      collection.has_next_page?.should be_false
    end

    it "iterates across all pages via each" do
      stub_api_request(:get, "query/?q=SELECT+Id+FROM+Account", "query_paginated_first_page_response")
      stub_api_request(:get, "query/01gD", "query_paginated_last_page_response")
      client = build_client
      collection = client.query_with_pagination("SELECT Id FROM Account")
      all_records = [] of JSON::Any
      collection.each { |r| all_records << r }
      all_records.size.should eq(2)
      all_records[0]["Text_Label"].as_s.should eq("First Page")
      all_records[1]["Text_Label"].as_s.should eq("Last Page")
    end

    it "works as an iterator" do
      stub_api_request(:get, "query/?q=SELECT+Id+FROM+Account", "query_paginated_first_page_response")
      stub_api_request(:get, "query/01gD", "query_paginated_last_page_response")
      client = build_client
      collection = client.query_with_pagination("SELECT Id FROM Account")

      first = collection.next
      first.should be_a(JSON::Any)
      first.as(JSON::Any)["Text_Label"].as_s.should eq("First Page")

      second = collection.next
      second.should be_a(JSON::Any)
      second.as(JSON::Any)["Text_Label"].as_s.should eq("Last Page")

      third = collection.next
      third.should be_a(Iterator::Stop)
    end
  end

  describe "single page results" do
    it "reports done and no next page" do
      stub_api_request(:get, "query/?q=SELECT+Id+FROM+Account", "query_success_response")
      client = build_client
      collection = client.query_with_pagination("SELECT Id FROM Account")
      collection.done.should be_true
      collection.has_next_page?.should be_false
      collection.size.should eq(1)
    end
  end
end
