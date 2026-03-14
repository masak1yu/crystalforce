require "http/client"
require "json"
require "base64"
require "uri"
require "openssl"

lib LibCrypto
  type EVP_PKEY = Void*
  type EVP_PKEY_CTX = Void*

  fun BIO_new_mem_buf(buf : UInt8*, len : Int32) : Bio*
  fun PEM_read_bio_PrivateKey(bp : Bio*, x : EVP_PKEY*, cb : Void*, u : Void*) : EVP_PKEY
  fun EVP_DigestSignInit(ctx : EVP_MD_CTX, pctx : EVP_PKEY_CTX*, type : EVP_MD, e : Void*, pkey : EVP_PKEY) : Int32
  fun EVP_DigestSignUpdate(ctx : EVP_MD_CTX, d : UInt8*, cnt : LibC::SizeT) : Int32
  fun EVP_DigestSignFinal(ctx : EVP_MD_CTX, sig : UInt8*, siglen : LibC::SizeT*) : Int32
end

module Crystalforce
  class Authentication
    def self.authenticate(
      username : String? = nil,
      password : String? = nil,
      security_token : String? = nil,
      client_id : String? = nil,
      client_secret : String? = nil,
      refresh_token : String? = nil,
      jwt_key : String? = nil,
      host : String? = nil,
    )
      actual_host = host || "login.salesforce.com"
      if jwt_key && client_id && username
        authenticate_jwt(jwt_key, client_id, username, actual_host)
      elsif client_id && client_secret && !username && !refresh_token && !jwt_key
        authenticate_client_credentials(client_id, client_secret, actual_host)
      elsif username && password && client_id && client_secret
        authenticate_password(username, password, security_token, client_id, client_secret, actual_host)
      elsif refresh_token && client_id && client_secret
        authenticate_refresh_token(refresh_token, client_id, client_secret, actual_host)
      end
    end

    private def self.authenticate_password(username, password, security_token, client_id, client_secret, host)
      form = URI::Params.encode({
        "grant_type"    => "password",
        "client_id"     => client_id,
        "client_secret" => client_secret,
        "username"      => username,
        "password"      => "#{password}#{security_token}",
      })
      HTTP::Client.post("https://#{host}/services/oauth2/token", form: form)
    end

    private def self.authenticate_refresh_token(refresh_token, client_id, client_secret, host)
      form = URI::Params.encode({
        "grant_type"    => "refresh_token",
        "refresh_token" => refresh_token,
        "client_id"     => client_id,
        "client_secret" => client_secret,
      })
      HTTP::Client.post("https://#{host}/services/oauth2/token", form: form)
    end

    private def self.authenticate_jwt(jwt_key, client_id, username, host)
      assertion = build_jwt(jwt_key, client_id, username, host)
      form = URI::Params.encode({
        "grant_type" => "urn:ietf:params:oauth:grant-type:jwt-bearer",
        "assertion"  => assertion,
      })
      HTTP::Client.post("https://#{host}/services/oauth2/token", form: form)
    end

    private def self.authenticate_client_credentials(client_id, client_secret, host)
      form = URI::Params.encode({
        "grant_type"    => "client_credentials",
        "client_id"     => client_id,
        "client_secret" => client_secret,
      })
      HTTP::Client.post("https://#{host}/services/oauth2/token", form: form)
    end

    private def self.build_jwt(private_key_pem : String, client_id : String, username : String, host : String) : String
      header = {"alg" => "RS256", "typ" => "JWT"}
      payload = {
        "iss" => client_id,
        "sub" => username,
        "aud" => "https://#{host}",
        "exp" => Time.utc.to_unix + 300,
      }

      header_b64 = base64url_encode(header.to_json)
      payload_b64 = base64url_encode(payload.to_json)
      signing_input = "#{header_b64}.#{payload_b64}"

      signature = rsa_sha256_sign(private_key_pem, signing_input)
      signature_b64 = base64url_encode_raw(signature)

      "#{signing_input}.#{signature_b64}"
    end

    private def self.rsa_sha256_sign(pem : String, data : String) : Bytes
      bio = LibCrypto.BIO_new_mem_buf(pem.to_unsafe, pem.bytesize)
      raise AuthenticationError.new("Failed to create BIO") unless bio

      pkey = LibCrypto.PEM_read_bio_PrivateKey(bio, nil, nil, nil)
      LibCrypto.BIO_free(bio)
      raise AuthenticationError.new("Failed to read private key") unless pkey

      ctx = LibCrypto.evp_md_ctx_new
      raise AuthenticationError.new("Failed to create EVP_MD_CTX") unless ctx

      begin
        pctx = Pointer(Void).null.as(LibCrypto::EVP_PKEY_CTX)
        if LibCrypto.EVP_DigestSignInit(ctx, pointerof(pctx), LibCrypto.evp_sha256, nil, pkey) != 1
          raise AuthenticationError.new("Failed to initialize signing")
        end

        if LibCrypto.EVP_DigestSignUpdate(ctx, data.to_unsafe, data.bytesize) != 1
          raise AuthenticationError.new("Failed to update signing")
        end

        sig_len = LibC::SizeT.new(0)
        if LibCrypto.EVP_DigestSignFinal(ctx, nil, pointerof(sig_len)) != 1
          raise AuthenticationError.new("Failed to get signature length")
        end

        signature = Bytes.new(sig_len)
        if LibCrypto.EVP_DigestSignFinal(ctx, signature, pointerof(sig_len)) != 1
          raise AuthenticationError.new("Failed to finalize signature")
        end

        signature[0, sig_len]
      ensure
        LibCrypto.evp_md_ctx_free(ctx)
      end
    end

    private def self.base64url_encode(data : String) : String
      Base64.urlsafe_encode(data).gsub("=", "")
    end

    private def self.base64url_encode_raw(data : Bytes) : String
      Base64.urlsafe_encode(data).gsub("=", "")
    end
  end
end
