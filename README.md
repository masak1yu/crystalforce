# crystalforce

Crystalforce is a crystal shards for the Salesforce REST api.

## Installation


Add this to your application's `shard.yml`:

```yaml
dependencies:
  crystalforce:
    github: msky026/crystalforce
```


## Usage


```crystal
require "crystalforce"
```

### Initialization

#### Username/Password authentication

```crystal
client = Crystalforce.new({
  :username       => "foo",
  :password       => "bar",
  :security_token => "security_token",
  :client_id      => "client_id",
  :client_secret  => "client_secret"
})
```

#### Sandbox Orgs

You can connect to sandbox orgs by specifying a host. The default host is
'login.salesforce.com':

```crystal
client = Crystalforce.new({:host => 'test.salesforce.com'})
```

### API versions

By default, the shard defaults to using version 34.0 of the Salesforce API.
Some more recent API endpoints will not be available without moving to a more recent
version - if you're trying to use a method that is unavailable with your API version,
Restforce will raise an `APIVersionError`.

You can change the `api_version` setting from the default either on a per-client basis:

```crystal
client = Crystalforce.new({api_version: "36.0" # ...})
```

### query

```crystal
accounts = client.query("select Id, Something__c from Account where Id = 'someid'")
```

### query_all

```crystal
accounts = client.query_all("select Id, Something__c from Account where isDeleted = true")
```

query_all allows you to include results from your query that Salesforce hides in the default "query" method.  These include soft-deleted records and archived records (e.g. Task and Event records which are usually archived automatically after they are a year old).

*Only available in [version 29.0](#api-versions) and later of the Salesforce API.*

### create

```crystal
# Add a new account
client.create("Account", {:Name => "Foobar Inc.""})
# => '0016000000MRatd'
```

### update

```crystal
# Update the Account with `Id` '0016000000MRatd'
client.update("Account", "0016000000MRatd", {:Name => "Whizbang Corp"})
# => true
```

### upsert

```crystal
# Update the record with external `External__c` external ID set to '12'
client.upsert("Account", "External__c", "External__c" => 12, "Name" => "Foobar")
# => response.body["id"] or true
```

### destroy

```crystal
# Delete the Account with `Id` '0016000000MRatd'
client.destroy("Account", "0016000000MRatd")
# => true
```

## notice

If you are using TLS 1.0 or earlier version of the library, update the ssl library to the latest one and use the following option.

```
crystal run --link-flags "-L/path/to/openssl/lib/" <file>
```

## Contributing

1. Fork it ( https://github.com/msky026/crystalforce/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [msky](https://github.com/msky026) - creator, maintainer
