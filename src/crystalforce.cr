require "./crystalforce/*"

module Crystalforce
  def self.new(args : Hash(Symbol, String))
    Crystalforce::Client.new(args)
  end
end
