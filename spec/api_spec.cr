require "./spec_helper"

describe "Crystalforce::Api" do
  describe "#query" do
    it "returns records from SOQL query" do
      stub_api_request(:get, "query/?q=SELECT+Id+FROM+Account", "query_success_response")
      client = build_client
      records = client.query("SELECT Id FROM Account")
      records.should be_a(JSON::Any)
      records.as_a.size.should eq(1)
    end

    it "returns empty array for empty results" do
      stub_api_request(:get, "query/?q=SELECT+Id+FROM+Account", "query_empty_response")
      client = build_client
      records = client.query("SELECT Id FROM Account")
      records.as_a.size.should eq(0)
    end

    it "raises on query error" do
      stub_api_request(:get, "query/?q=SELECT+Invalid+FROM+Account", nil, status: 400, body: fixture("sobject/query_error_response"))
      client = build_client
      expect_raises(Crystalforce::ServerError, /error_message/) do
        client.query("SELECT Invalid FROM Account")
      end
    end
  end

  describe "#query_all" do
    it "returns records including deleted" do
      stub_api_request(:get, "queryAll/?q=SELECT+Id+FROM+Account", "query_success_response")
      client = build_client
      records = client.query_all("SELECT Id FROM Account")
      records.as_a.size.should eq(1)
    end
  end

  describe "#search" do
    it "returns search results" do
      stub_api_request(:get, "search/?q=FIND+%7Btest%7D", "search_success_response")
      client = build_client
      results = client.search("FIND {test}")
      results.as_a.size.should eq(2)
    end
  end

  describe "#find" do
    it "finds a record by id" do
      stub_api_request(:get, "sobjects/Whizbang/23foo", "sobject_find_success_response")
      client = build_client
      record = client.find("Whizbang", "23foo")
      record["Id"].as_s.should eq("23foo")
      record["Name"].as_s.should eq("My First Whizbang")
    end

    it "finds a record by external id" do
      stub_api_request(:get, "sobjects/Whizbang/External__c/abc", "sobject_find_success_response")
      client = build_client
      record = client.find("Whizbang", "abc", field: "External__c")
      record["Id"].as_s.should eq("23foo")
    end

    it "raises NotFoundError when record not found" do
      stub_api_request(:get, "sobjects/Whizbang/not_found", nil, status: 404, body: fixture("sobject/sobject_find_error_response"))
      client = build_client
      expect_raises(Crystalforce::NotFoundError) do
        client.find("Whizbang", "not_found")
      end
    end
  end

  describe "#select" do
    it "returns selected fields" do
      stub_api_request(:get, "sobjects/Whizbang/23foo?fields=External_Field__c%2CId", "sobject_select_success_response")
      client = build_client
      record = client.select("Whizbang", "23foo", ["External_Field__c", "Id"])
      record["Id"].as_s.should eq("23foo")
      record["External_Field__c"].as_s.should eq("1234")
    end
  end

  describe "#create" do
    it "returns raw response" do
      stub_api_request(:post, "sobjects/Account/", "create_success_response", status: 201)
      client = build_client
      response = client.create("Account", {"Name" => "Test"})
      response.status_code.should eq(201)
    end
  end

  describe "#create!" do
    it "returns parsed response with id" do
      stub_api_request(:post, "sobjects/Account/", "create_success_response", status: 201)
      client = build_client
      result = client.create!("Account", {"Name" => "Test"})
      result["id"].as_s.should eq("some_id")
      result["success"].as_bool.should be_true
    end

    it "raises on error" do
      stub_api_request(:post, "sobjects/Account/", nil, status: 400, body: fixture("sobject/write_error_response"))
      client = build_client
      expect_raises(Crystalforce::ServerError, /No such column/) do
        client.create!("Account", {"foo" => "bar"})
      end
    end
  end

  describe "#update" do
    it "returns response" do
      stub_api_request(:patch, "sobjects/Account/001", nil, status: 204)
      client = build_client
      response = client.update("Account", "001", {"Name" => "Updated"})
      response.status_code.should eq(204)
    end
  end

  describe "#update!" do
    it "returns true on success" do
      stub_api_request(:patch, "sobjects/Account/001", nil, status: 204)
      client = build_client
      result = client.update!("Account", "001", {"Name" => "Updated"})
      result.should be_true
    end

    it "raises on error" do
      stub_api_request(:patch, "sobjects/Account/001", nil, status: 400, body: fixture("sobject/write_error_response"))
      client = build_client
      expect_raises(Crystalforce::ServerError) do
        client.update!("Account", "001", {"foo" => "bar"})
      end
    end
  end

  describe "#upsert!" do
    it "creates a new record via upsert" do
      stub_api_request(:patch, "sobjects/Account/External__c/123", "upsert_created_success_response", status: 201)
      client = build_client
      result = client.upsert!("Account", "External__c", {"External__c" => "123", "Name" => "Test"})
      result.should_not be_nil
    end

    it "updates an existing record via upsert" do
      stub_api_request(:patch, "sobjects/Account/External__c/123", nil, status: 204)
      client = build_client
      result = client.upsert!("Account", "External__c", {"External__c" => "123", "Name" => "Updated"})
      result.should be_true
    end
  end

  describe "#destroy" do
    it "returns response" do
      stub_api_request(:delete, "sobjects/Account/001", nil, status: 204)
      client = build_client
      response = client.destroy("Account", "001")
      response.status_code.should eq(204)
    end
  end

  describe "#destroy!" do
    it "returns true on success" do
      stub_api_request(:delete, "sobjects/Account/001", nil, status: 204)
      client = build_client
      result = client.destroy!("Account", "001")
      result.should be_true
    end

    it "raises on error" do
      stub_api_request(:delete, "sobjects/Account/001", nil, status: 404, body: fixture("sobject/delete_error_response"))
      client = build_client
      expect_raises(Crystalforce::NotFoundError) do
        client.destroy!("Account", "001")
      end
    end
  end

  describe "#describe" do
    it "describes all sobjects" do
      stub_api_request(:get, "sobjects", "describe_sobjects_success_response")
      client = build_client
      result = client.describe
      result["sobjects"].as_a.size.should be > 0
    end

    it "describes a specific sobject" do
      stub_api_request(:get, "sobjects/Whizbang/describe", "describe_sobject_success_response")
      client = build_client
      result = client.describe("Whizbang")
      result["name"].as_s.should eq("Whizbang")
    end
  end

  describe "#list_sobjects" do
    it "returns array of sobject names" do
      stub_api_request(:get, "sobjects", "describe_sobjects_success_response")
      client = build_client
      names = client.list_sobjects
      names.should contain("Account")
    end
  end

  describe "#limits" do
    it "returns org limits" do
      stub_api_request(:get, "limits", "limits_success_response")
      client = build_client
      result = client.limits
      result["DailyApiRequests"]["Max"].as_i.should eq(15000)
    end
  end

  describe "#user_info" do
    it "returns current user info" do
      WebMock.stub(:get, "https://na1.salesforce.com/services/oauth2/userinfo")
        .to_return(status: 200, body: fixture("sobject/user_info_response"))
      client = build_client
      result = client.user_info
      result["email"].as_s.should eq("user@example.com")
    end
  end

  describe "#org_id" do
    it "returns organization id" do
      stub_api_request(:get, "query/?q=SELECT+Id+FROM+Organization", "org_query_response")
      client = build_client
      result = client.org_id
      result.should eq("00Dx0000000BV7z")
    end
  end

  describe "#get_updated" do
    it "returns updated record ids" do
      start_time = Time.utc(2015, 8, 18)
      end_time = Time.utc(2015, 8, 19)
      stub_api_request(:get, "sobjects/Account/updated/?start=2015-08-18T00%3A00%3A00Z&end=2015-08-19T00%3A00%3A00Z", "get_updated_success_response")
      client = build_client
      result = client.get_updated("Account", start_time, end_time)
      result["ids"].as_a.size.should eq(2)
    end
  end

  describe "#get_deleted" do
    it "returns deleted record info" do
      start_time = Time.utc(2013, 5, 3)
      end_time = Time.utc(2013, 5, 8)
      stub_api_request(:get, "sobjects/Account/deleted/?start=2013-05-03T00%3A00%3A00Z&end=2013-05-08T00%3A00%3A00Z", "get_deleted_success_response")
      client = build_client
      result = client.get_deleted("Account", start_time, end_time)
      result["deletedRecords"].as_a.size.should eq(1)
    end
  end

  describe "#recent" do
    it "returns recently accessed items" do
      stub_api_request(:get, "recent", "recent_success_response")
      client = build_client
      result = client.recent
      result.as_a.size.should eq(1)
    end
  end

  describe "#explain" do
    it "returns query execution plan" do
      body = %({"plans":[{"cardinality":1,"fields":[],"leadingOperationType":"TableScan","relativeCost":1.0,"sobjectCardinality":1,"sobjectType":"Account"}]})
      stub_api_request(:get, "query/?explain=SELECT+Id+FROM+Account", nil, body: body)
      client = build_client
      result = client.explain("SELECT Id FROM Account")
      result["plans"].as_a.size.should eq(1)
    end
  end

  describe "#picklist_values" do
    it "returns picklist values for a field" do
      stub_api_request(:get, "sobjects/Whizbang/describe", "describe_sobject_success_response")
      client = build_client
      values = client.picklist_values("Whizbang", "Stage")
      values.size.should eq(3)
      values.map { |v| v["value"].as_s }.should contain("Open")
    end

    it "returns dependent picklist values filtered by controlling value" do
      stub_api_request(:get, "sobjects/Whizbang/describe", "describe_sobject_success_response")
      client = build_client
      values = client.picklist_values("Whizbang", "SubStage", valid_for: "Open")
      values.each do |v|
        v["value"].as_s.should match(/Open/)
      end
    end

    it "raises error for non-existent field" do
      stub_api_request(:get, "sobjects/Whizbang/describe", "describe_sobject_success_response")
      client = build_client
      expect_raises(Crystalforce::ServerError, /not found/) do
        client.picklist_values("Whizbang", "NonExistent")
      end
    end

    it "raises error when field is not a dependent picklist" do
      stub_api_request(:get, "sobjects/Whizbang/describe", "describe_sobject_success_response")
      client = build_client
      expect_raises(Crystalforce::ServerError, /not a dependent picklist/) do
        client.picklist_values("Whizbang", "Stage", valid_for: "Open")
      end
    end
  end
end
