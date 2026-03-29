require "spec"
require "webmock"
require "../src/crystalforce"

Spec.before_each do
  WebMock.reset
end

FIXTURE_PATH = File.join(__DIR__, "fixtures")

def fixture(filename : String) : String
  File.read(File.join(FIXTURE_PATH, "#{filename}.json"))
end

lib LibCrypto
  fun RSA_generate_key_ex(rsa : Void*, bits : Int32, e : Void*, cb : Void*) : Int32
  fun RSA_new : Void*
  fun BN_new : Void*
  fun BN_set_word(a : Void*, w : UInt64) : Int32
  fun PEM_write_bio_RSAPrivateKey(bp : Bio*, x : Void*, enc : Void*, kstr : Void*, klen : Int32, cb : Void*, u : Void*) : Int32
  fun BIO_ctrl_pending(b : Bio*) : LibC::SizeT
  fun BIO_read(b : Bio*, data : UInt8*, dlen : Int32) : Int32
  fun BIO_s_mem : BioMethod*
end

def generate_test_rsa_key : String
  rsa = LibCrypto.RSA_new
  e = LibCrypto.BN_new
  LibCrypto.BN_set_word(e, 65537_u64)
  LibCrypto.RSA_generate_key_ex(rsa, 2048, e, nil)

  bio = LibCrypto.BIO_new(LibCrypto.BIO_s_mem)
  LibCrypto.PEM_write_bio_RSAPrivateKey(bio, rsa, nil, nil, 0, nil, nil)
  len = LibCrypto.BIO_ctrl_pending(bio)
  buf = Bytes.new(len)
  LibCrypto.BIO_read(bio, buf, len.to_i32)
  String.new(buf)
end

def auth_success_body
  fixture("auth_success_response")
end

def stub_auth_request
  WebMock.stub(:post, "https://login.salesforce.com/services/oauth2/token")
    .to_return(status: 200, body: auth_success_body, headers: {"Content-Type" => "application/json"})
end

def stub_api_request(method : Symbol, endpoint : String, fixture_name : String? = nil, status : Int32 = 200, api_version : String = "34.0", body : String? = nil)
  url = "https://na1.salesforce.com/services/data/v#{api_version}/#{endpoint.lstrip('/')}"
  stub = WebMock.stub(method, url)
  if fixture_name
    stub.to_return(status: status, body: fixture("sobject/#{fixture_name}"), headers: {"Content-Type" => "application/json"})
  elsif body
    stub.to_return(status: status, body: body, headers: {"Content-Type" => "application/json"})
  else
    stub.to_return(status: status, body: "", headers: {"Content-Type" => "application/json"})
  end
  stub
end

def build_client(**options)
  stub_auth_request
  defaults = {
    username:       "user@example.com",
    password:       "password",
    security_token: "token",
    client_id:      "client_id",
    client_secret:  "client_secret",
  }
  Crystalforce::Client.new(**defaults.merge(options))
end
