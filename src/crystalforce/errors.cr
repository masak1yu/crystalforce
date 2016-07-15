module Crystalforce
  class Error < Exception; end

  class ServerError < Error; end

  class AuthenticationError < Error; end

  class UnauthorizedError < Error; end

  class APIVersionError < Error; end
end
