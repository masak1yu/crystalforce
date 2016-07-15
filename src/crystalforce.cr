require "./crystalforce/*"

module Crystalforce
  def self.new(args : Hash)
    Crystalforce::Client.new(args)
  end
end
