require "./spec_helper"

describe Crystalforce::Canvas do
  describe ".decode_signed_request" do
    it "decodes a valid signed request" do
      secret = "my_secret"
      payload_data = {"test" => "data", "number" => 42}
      encoded_payload = Base64.strict_encode(payload_data.to_json)

      # Calculate HMAC signature
      signature = OpenSSL::HMAC.digest(:sha256, secret, encoded_payload)
      encoded_signature = Base64.strict_encode(signature)

      signed_request = "#{encoded_signature}.#{encoded_payload}"

      result = Crystalforce::Canvas.decode_signed_request(signed_request, secret)
      result.should_not be_nil
      result.not_nil!["test"].as_s.should eq("data")
      result.not_nil!["number"].as_i.should eq(42)
    end

    it "returns nil for invalid signature" do
      secret = "my_secret"
      payload_data = {"test" => "data"}
      encoded_payload = Base64.strict_encode(payload_data.to_json)

      # Use wrong signature
      bad_signature = Base64.strict_encode("wrong_signature_bytes_pad_pad_32")

      signed_request = "#{bad_signature}.#{encoded_payload}"

      result = Crystalforce::Canvas.decode_signed_request(signed_request, secret)
      result.should be_nil
    end

    it "returns nil for malformed request (no dot separator)" do
      result = Crystalforce::Canvas.decode_signed_request("nodothere", "secret")
      result.should be_nil
    end

    it "returns nil for empty parts" do
      result = Crystalforce::Canvas.decode_signed_request(".", "secret")
      result.should be_nil
    end
  end
end
