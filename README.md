# puppetdb_query - query puppetdb data from other sources

Just store and update your puppet facts also in another database and query nodes or facts from that other database.
This can speed up your queries enormously and reduce the load on your puppet database.

## General

The puppet database schema is not designed for complicated queries on numerous nodes. Here we provide
an implementation for storing and querying node facts in a mongodb.  

You must simply establish a sync job to read the data from your puppetdb and write it to a mongodb.

Currently the implementation supports only puppetdb api V 4.

## Installation
The example implementation uses a mongodb (version >= 3.2).

Add this line to your application's Gemfile:

```ruby
gem 'puppetdb_query'
gem 'mongo', '>=2.2.0'
```

and then execute:

    $ bundle install

Or install it yourself as:

    $ gem install puppetdb_query
    $ gem install mongo 

## Usage

First you have to sync your puppetdb data with your mongodb.
You can accomplish this by calling the following code every 5 minutes.

```ruby
#!/bin/ruby

require 'mongo'
require 'puppetdb_query'

include PuppetDBQuery::Logging
logger.level = Logger::INFO
::Mongo::Logger.logger = logger

begin
  MONGO_HOSTS = ['puppetdb-mongo.example.com:27017']
  MONGO_OPTIONS = { database: 'puppetdb', user: 'ops', password: 'very secret' }
  connection = ::Mongo::Client.new(MONGO_HOSTS, MONGO_OPTIONS)
  mongodb = PuppetDBQuery::MongoDB.new(connection)
  puppetdb = PuppetDBQuery::PuppetDB.new('puppetdb-querynodes.example.com')

  sync = PuppetDBQuery::Sync.new(puppetdb, mongodb)
  sync.sync(5, 10)
rescue
  logger.error $!
end
```


Now you can query nodes and facts like this:

```ruby
require "mongo"
require "puppetdb_query"
require "pp"

MONGO_HOSTS = ['puppetdb-mongo.example.com:27017']
MONGO_OPTIONS = { database: 'puppetdb', user: 'ops', password: 'very secret' }

pm = PuppetDBQuery::MongoQuery.new(MONGO_HOSTS, MONGO_OPTIONS)
pm.nodes({processorcount: '4', lvm_support: true})
pm.facts({processorcount: '4', lvm_support: true}, ["macaddress", "operatingsystem"])

mongo = PuppetDBQuery::ToMongo.new
query = mongo.query("processorcount='4' and lvm_support=true")
pp query
pm.nodes(query)
pm.facts(query, ["macaddress", "operatingsystem"])
```

## Development

After checking out the repo, run `bundle install` to install dependencies.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release` to create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

Travis results under (https://travis-ci.org/m-31/puppetdb_query)

## Contributing

1. Fork it ( https://github.com/m-31/puppetdb_query/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
