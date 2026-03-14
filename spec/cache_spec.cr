require "./spec_helper"

describe Crystalforce::MemoryCache do
  describe "#read" do
    it "returns nil for missing key" do
      cache = Crystalforce::MemoryCache.new
      cache.read("missing").should be_nil
    end

    it "returns stored value" do
      cache = Crystalforce::MemoryCache.new
      cache.write("key", "value")
      cache.read("key").should eq("value")
    end
  end

  describe "#write" do
    it "stores a value" do
      cache = Crystalforce::MemoryCache.new
      cache.write("key", "value")
      cache.read("key").should eq("value")
    end

    it "overwrites existing value" do
      cache = Crystalforce::MemoryCache.new
      cache.write("key", "old")
      cache.write("key", "new")
      cache.read("key").should eq("new")
    end
  end

  describe "#clear" do
    it "removes all entries" do
      cache = Crystalforce::MemoryCache.new
      cache.write("a", "1")
      cache.write("b", "2")
      cache.clear
      cache.size.should eq(0)
      cache.read("a").should be_nil
    end
  end

  describe "#size" do
    it "returns number of entries" do
      cache = Crystalforce::MemoryCache.new
      cache.size.should eq(0)
      cache.write("a", "1")
      cache.size.should eq(1)
    end
  end
end

describe "API caching" do
  it "caches GET responses" do
    cache = Crystalforce::MemoryCache.new
    stub_api_request(:get, "limits", "limits_success_response")
    client = build_client(cache: cache)

    # First call hits the API
    client.limits
    cache.size.should be > 0

    # Second call should use cache (no additional HTTP request needed)
    result = client.limits
    result["DailyApiRequests"]["Max"].as_i.should eq(15000)
  end
end
