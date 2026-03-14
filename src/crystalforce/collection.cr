module Crystalforce
  # Lazy-paginating collection for query results.
  # Implements Enumerable and Iterator for automatic pagination.
  class Collection
    include Enumerable(JSON::Any)
    include Iterator(JSON::Any)

    getter total_size : Int64
    getter done : Bool

    def initialize(@records : Array(JSON::Any), @total_size : Int64, @done : Bool, @next_records_url : String?, @client : Client | ToolingClient)
      @index = 0
      @current_page = @records
    end

    def size
      @total_size
    end

    def current_page
      @current_page
    end

    def has_next_page?
      !@done && !@next_records_url.nil?
    end

    def next_page : Array(JSON::Any)?
      return nil unless has_next_page?
      url = @next_records_url.not_nil!
      response = @client.api_get(url.sub(/.*\/services\/data\/v[\d.]+/, ""))
      parsed = JSON.parse(response.body)
      @current_page = parsed["records"].as_a
      @done = parsed["done"].as_bool
      @next_records_url = parsed["nextRecordsUrl"]?.try(&.as_s)
      @current_page
    end

    # Enumerable - iterate all records across all pages
    def each(&)
      @current_page.each { |r| yield r }
      while has_next_page?
        page = next_page
        break unless page
        page.each { |r| yield r }
      end
    end

    # Iterator
    def next
      if @index < @current_page.size
        record = @current_page[@index]
        @index += 1
        record
      elsif has_next_page?
        page = next_page
        return stop unless page && page.size > 0
        @index = 1
        page[0]
      else
        stop
      end
    end

    def rewind
      @index = 0
      self
    end
  end
end
