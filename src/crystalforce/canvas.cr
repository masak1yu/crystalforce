require "openssl/hmac"
require "base64"
require "json"

module Crystalforce
  module Canvas
    def self.decode_signed_request(signed_request : String, client_secret : String) : JSON::Any?
      parts = signed_request.split(".")
      return nil unless parts.size == 2

      encoded_signature = parts[0]
      payload = parts[1]

      # Calculate expected HMAC-SHA256
      expected = OpenSSL::HMAC.digest(:sha256, client_secret, payload)
      signature = Base64.decode(encoded_signature)

      # Constant-time comparison
      return nil unless secure_compare(signature, expected)

      # Decode and parse payload
      decoded_payload = Base64.decode_string(payload)
      JSON.parse(decoded_payload)
    end

    private def self.secure_compare(a : Bytes, b : Bytes) : Bool
      return false unless a.size == b.size
      result = 0
      a.size.times do |i|
        result |= a[i] ^ b[i]
      end
      result == 0
    end
  end
end
