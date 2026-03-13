# crystalforce

Crystalforce is a Crystal shard for the Salesforce REST API.

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

#### Sandbox Orgs

You can connect to sandbox orgs by specifying a host. The default host is
`login.salesforce.com`:

```crystal
client = Crystalforce.new(
  host:          "test.salesforce.com",
  username:       "foo",
  password:       "bar",
  security_token: "security_token",
  client_id:      "client_id",
  client_secret:  "client_secret",
)
```

### API versions

By default, the shard uses version 34.0 of the Salesforce API.
You can change the `api_version` on a per-client basis:

```crystal
client = Crystalforce.new(
  api_version: "36.0",
  username:    "foo",
  password:    "bar",
  client_id:   "client_id",
  client_secret: "client_secret",
)
```

### query

```crystal
accounts = client.query("select Id, Something__c from Account where Id = 'someid'")
```

### query_all

```crystal
accounts = client.query_all("select Id, Something__c from Account where isDeleted = true")
```

`query_all` allows you to include results from your query that Salesforce hides in the default `query` method. These include soft-deleted records and archived records (e.g. Task and Event records which are usually archived automatically after they are a year old).

### create

```crystal
client.create("Account", {:Name => "Foobar Inc."})
```

### update

```crystal
client.update("Account", "0016000000MRatd", {:Name => "Whizbang Corp"})
```

### upsert

```crystal
client.upsert("Account", "External__c", {"External__c" => "12", "Name" => "Foobar"})
```

### destroy

```crystal
client.destroy("Account", "0016000000MRatd")
```

## Contributing

1. Fork it ( https://github.com/masak1yu/crystalforce/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request

## Contributors

- [masak1yu](https://github.com/masak1yu) - creator, maintainer
