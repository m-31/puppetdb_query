# puppetdb_query - query puppetdb data from other sources

Just store update your puppet facts in a mongodb and query it analogous to query nodes or query facts.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'puppetdb_query'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install puppetdb_query 

## Usage within program

```ruby
require "mongo"
require "puppetdb_query"
require "pp"

MONGO_HOSTS = ['mongo.myhost.org:27017']
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

## Contributing

1. Fork it ( https://github.com/m-31/puppetdb_query/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
