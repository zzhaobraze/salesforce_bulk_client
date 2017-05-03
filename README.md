# SalesforceBulkClient

SalesforceBulkClient is a Ruby gem which allows for integration with the Salesforce.com Bulk API.

Although there are many other gems to choose from for this purpose, this gem offers the following features:

* JSON is used for all API requests and responses (instead of XML) in order to reduce message size.
* Splitting data into batches for inserts, updates, and deletes are handled automatically. Batches will be split
  further if the 10,000,000 character limit per batch would be exceeded.
* Large sets of data can be processed without pre-loading multiple batches.
* Connect using the Restforce client instance.

## Installation

Add this line to Gemfile:

```ruby
gem 'salesforce_bulk_client'
```

And then execute:

    $ bundle

Or install it as follows:

    $ gem install salesforce_bulk_client

## Usage

### Instantiate the Bulk API Client

Authentication is done via the Restforce gem:

```ruby
require 'salesforce_bulk_client'
restforce_client = Restforce.new(
    username:       ENV['SALESFORCE_USERNAME'],
    password:       ENV['SALESFORCE_PASSWORD'],
    security_token: ENV['SALESFORCE_SECURITY_TOKEN'],
    client_id:      ENV['SALESFORCE_OAUTH_CONSUMER_KEY'],
    client_secret:  ENV['SALESFORCE_OAUTH_CONSUMER_SECRET'].to_i,
    host:           ENV['SALESFORCE_HOST'])
bulk_client = SalesforceBulkClient::Client.new(restforce_client)
```

### Inserting records

```ruby
records = [ { Name: 'Test Account 1' }, { Name: 'Test Account 2' } ]
result = bulk_client.insert(sobject, records)
```

### Upserting records

```ruby
records = [ { Id: '00136000014tyyF', Name: 'Test Account 1' }, { Name: 'Test Account 2' } ]
result = bulk_client.upsert(sobject, records, 'Id')
```

### Updating records

```ruby
records = [ { Id: '00136000014tyyF', Name: 'Test Account 1' }, { Id: '00136000014tyyP', Name: 'Test Account 2' } ]
result = bulk_client.update(sobject, records)
```

### Deleting records

```ruby
records = [ { Id: '00136000014tyyF' }, { Id: '00136000014tyyP' } ]
result = bulk_client.delete(sobject, records)
```

### Query records

```ruby
result = bulk_client.query('Account', "select Id, Name from Account where Id = '00136000014tyyF'", true)
```

### Process batches without pre-loading
```ruby
result = bulk_client.query('Account', "select Id, Name from Account where Id = '00136000014tyyF'", false)
bulk_client.job_from_id(result.id).each_batch do |batch, batch_results|
  # Add batch-level processing logic here
end
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/FronteraConsulting/salesforce_bulk_client.

