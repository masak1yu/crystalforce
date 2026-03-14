module Crystalforce
  # Cache interface. Implement this module to provide custom caching.
  module Cache
    abstract def read(key : String) : String?
    abstract def write(key : String, value : String) : Nil
  end

  # Simple in-memory cache implementation
  class MemoryCache
    include Cache

    def initialize
      @store = Hash(String, String).new
    end

    def read(key : String) : String?
      @store[key]?
    end

    def write(key : String, value : String) : Nil
      @store[key] = value
    end

    def clear
      @store.clear
    end

    def size
      @store.size
    end
  end
end
