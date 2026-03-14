# crystalforce

[![CI](https://github.com/masak1yu/crystalforce/actions/workflows/ci.yml/badge.svg)](https://github.com/masak1yu/crystalforce/actions/workflows/ci.yml)

Crystalforce is a Crystal shard for the Salesforce REST API.
A Crystal port of [Restforce](https://github.com/restforce/restforce).

## Installation

Add this to your application's `shard.yml`:

```yaml
dependencies:
  crystalforce:
    github: masak1yu/crystalforce
```

Then run:

```sh
shards install
```

## Development

### Build

```sh
shards build
```

### Run tests

```sh
crystal spec
```

### Check formatting

```sh
crystal tool format --check
```

## Usage

```crystal
require "crystalforce"
```

### Initialization

#### Username/Password authentication

```crystal
client = Crystalforce.new(
  username:       "foo",
  password:       "bar",
  security_token: "security_token",
  client_id:      "client_id",
  client_secret:  "client_secret",
)
```

#### OAuth token refresh

```crystal
client = Crystalforce.new(
  refresh_token: "refresh_token",
  client_id:     "client_id",
  client_secret: "client_secret",
)
```

#### JWT Bearer authentication

```crystal
jwt_key = File.read("path/to/private_key.pem")
client = Crystalforce.new(
  username:  "foo",
  client_id: "client_id",
  jwt_key:   jwt_key,
)
```

#### Client Credentials authentication

Requires the `host` to be set to your My Domain URL:

```crystal
client = Crystalforce.new(
  client_id:     "client_id",
  client_secret: "client_secret",
  host:          "yourdomain.my.salesforce.com",
)
```

#### Sandbox Orgs

You can connect to sandbox orgs by specifying a host. The default host is
`login.salesforce.com`:

```crystal
client = Crystalforce.new(
  host:           "test.salesforce.com",
  username:       "foo",
  password:       "bar",
  security_token: "security_token",
  client_id:      "client_id",
  client_secret:  "client_secret",
)
```

### Options

#### API versions

By default, the shard uses version 34.0 of the Salesforce API.
You can change the `api_version` on a per-client basis:

```crystal
client = Crystalforce.new(
  api_version:   "58.0",
  username:      "foo",
  password:      "bar",
  client_id:     "client_id",
  client_secret: "client_secret",
)
```

#### Authentication retries

When an API call returns a 401 Unauthorized, the client automatically
re-authenticates and retries the request. The default retry count is 3:

```crystal
client = Crystalforce.new(
  authentication_retries: 5,
  # ... auth params
)
```

#### Authentication callback

You can provide a callback that is invoked after each successful authentication
(including re-authentications on 401):

```crystal
callback = Proc(Crystalforce::Client, Nil).new do |client|
  puts "Authenticated! Token: #{client.access_token}"
end

client = Crystalforce.new(
  authentication_callback: callback,
  # ... auth params
)
```

#### Environment variables

Configuration can be provided via environment variables. Explicit parameters
take precedence over environment variables:

| Variable | Config key |
|----------|-----------|
| `SALESFORCE_USERNAME` | `username` |
| `SALESFORCE_PASSWORD` | `password` |
| `SALESFORCE_SECURITY_TOKEN` | `security_token` |
| `SALESFORCE_CLIENT_ID` | `client_id` |
| `SALESFORCE_CLIENT_SECRET` | `client_secret` |
| `SALESFORCE_HOST` | `host` |
| `SALESFORCE_API_VERSION` | `api_version` |
| `SALESFORCE_PROXY_URI` | `proxy_uri` |

```crystal
# Uses SALESFORCE_* environment variables as defaults
client = Crystalforce.new
```

#### Custom headers

Add custom headers to all requests:

```crystal
client = Crystalforce.new(
  request_headers: {"X-Custom-Header" => "value"},
  # ... auth params
)
```

#### Logging

Crystalforce uses Crystal's standard `Log` module under the `crystalforce` source.
Configure the log level to see request/response details:

```crystal
Log.setup("crystalforce", :debug)
```

#### GZIP compression

Enable GZIP compression for requests and responses:

```crystal
client = Crystalforce.new(
  compress: true,
  # ... auth params
)
```

#### SSL configuration

Provide a custom SSL context:

```crystal
ssl = OpenSSL::SSL::Context::Client.new
client = Crystalforce.new(
  ssl: ssl,
  # ... auth params
)
```

#### Proxy

Route requests through an HTTP proxy:

```crystal
client = Crystalforce.new(
  proxy_uri: "http://proxy.example.com:8080",
  # ... auth params
)
```

#### Caching

Cache GET request responses using the built-in `MemoryCache` or a custom
implementation of the `Crystalforce::Cache` module:

```crystal
cache = Crystalforce::MemoryCache.new
client = Crystalforce.new(
  cache: cache,
  # ... auth params
)
```

### Query

```crystal
accounts = client.query("select Id, Something__c from Account where Id = 'someid'")
```

#### Automatic pagination

Use `query_with_pagination` to get a `Collection` that automatically fetches
subsequent pages as you iterate:

```crystal
collection = client.query_with_pagination("SELECT Id, Name FROM Account")
puts collection.total_size
collection.each { |record| puts record["Name"] }
```

### query_all

```crystal
accounts = client.query_all("select Id, Something__c from Account where isDeleted = true")
```

`query_all` allows you to include results from your query that Salesforce hides in the default `query` method. These include soft-deleted records and archived records (e.g. Task and Event records which are usually archived automatically after they are a year old).

### search

```crystal
results = client.search("FIND {Foobar Inc.}")
```

### explain

```crystal
plan = client.explain("select Id from Account")
```

### find

```crystal
account = client.find("Account", "0016000000MRatd")

# Find by external ID
account = client.find("Account", "12345", "External__c")
```

### select

```crystal
account = client.select("Account", "0016000000MRatd", ["Id", "Name", "Industry"])
```

### create

```crystal
client.create("Account", {:Name => "Foobar Inc."})

# Bang version raises on error and returns parsed response
result = client.create!("Account", {:Name => "Foobar Inc."})
puts result["id"]
```

### update

```crystal
client.update("Account", "0016000000MRatd", {:Name => "Whizbang Corp"})

# Bang version raises on error
client.update!("Account", "0016000000MRatd", {:Name => "Whizbang Corp"})
```

### upsert

```crystal
client.upsert("Account", "External__c", {"External__c" => "12", "Name" => "Foobar"})

# Bang version raises on error
client.upsert!("Account", "External__c", {"External__c" => "12", "Name" => "Foobar"})
```

### destroy

```crystal
client.destroy("Account", "0016000000MRatd")

# Bang version raises on error
client.destroy!("Account", "0016000000MRatd")
```

### describe

```crystal
# Describe all SObjects
all = client.describe

# Describe a specific SObject
account_desc = client.describe("Account")
```

### describe_layouts

```crystal
layouts = client.describe_layouts("Account")
```

### list_sobjects

```crystal
names = client.list_sobjects
```

### limits

```crystal
limits = client.limits
```

### user_info

```crystal
info = client.user_info
```

### org_id

```crystal
id = client.org_id
```

### get_updated / get_deleted

```crystal
updated = client.get_updated("Account", Time.utc - 1.day, Time.utc)
deleted = client.get_deleted("Account", Time.utc - 1.day, Time.utc)
```

### recent

```crystal
items = client.recent(10)
```

### picklist_values

```crystal
values = client.picklist_values("Account", "Industry")

# Dependent picklist (filtered by controlling field value)
values = client.picklist_values("MyObject__c", "SubType__c", valid_for: "TypeA")
```

### Batch API

Execute up to 25 subrequests in a single call. Automatically chunks larger batches:

```crystal
results = client.batch do |b|
  b.create("Account", {:Name => "Batch1"})
  b.create("Account", {:Name => "Batch2"})
  b.update("Account", "001xx...", {:Name => "Updated"})
  b.destroy("Account", "001xx...")
end
```

### Composite API

Execute multiple dependent requests in a single call with reference IDs:

```crystal
results = client.composite do |c|
  c.create("Account", "newAccount", {:Name => "Composite1"})
  c.find("Account", "findAccount", "001xx...")
  c.update("Account", "updateAccount", "001xx...", {:Name => "Updated"})
  c.destroy("Account", "deleteAccount", "001xx...")
end
```

### Low-level HTTP

```crystal
response = client.api_get("/sobjects/Account/describe")
response = client.api_post("/sobjects/Account", {:Name => "Test"})
response = client.api_patch("/sobjects/Account/001xx...", {:Name => "Updated"})
response = client.api_put("/some/path", {:key => "value"})
response = client.api_delete("/sobjects/Account/001xx...")
```

### Tooling API

```crystal
tooling = Crystalforce.tooling(
  username:  "foo",
  client_id: "client_id",
  jwt_key:   jwt_key,
)

classes = tooling.query("SELECT Id, Name FROM ApexClass LIMIT 10")
desc = tooling.describe("ApexClass")
```

### Canvas

Decode and verify a Force.com Canvas signed request:

```crystal
result = Crystalforce::Canvas.decode_signed_request(signed_request, client_secret)
```

### Streaming API

Subscribe to PushTopics or Platform Events via CometD long-polling:

```crystal
streaming = client.streaming

# Subscribe to a PushTopic
streaming.subscribe("/topic/MyTopic") do |message|
  puts message
end

# Subscribe with replay
streaming.subscribe("/event/MyEvent__e", replay_id: -2_i64) do |message|
  puts message
end
```

## Contributing

1. Fork it ( https://github.com/masak1yu/crystalforce/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [masak1yu](https://github.com/masak1yu) - creator, maintainer
