require_relative "puppetdb_query/operator"
require_relative "puppetdb_query/term"
require_relative "puppetdb_query/tokenizer"
require_relative "puppetdb_query/parser"
require_relative "puppetdb_query/puppetdb"
require_relative "puppetdb_query/mongodb"
require_relative "puppetdb_query/to_mongo"
require_relative "puppetdb_query/updater"
require_relative "puppetdb_query/version"

module PuppetDBQuery

end

if $0 == __FILE__

  require "pp"
  query = "facts=-7.4E1 and fucts=8 and fits=true or lhotse_vertical='ops' and (lhotse_group=\"live\"or lhotse_group='prelive-cluster')"
  puts query
  query = PuppetDBQuery::Tokenizer.idem(query)
  puts query
  query = PuppetDBQuery::Tokenizer.idem(query)
  puts query

  parser = PuppetDBQuery::Parser.new(query)
  term = parser.parse
  pp term

  mongo = PuppetDBQuery::ToMongo.new
  pp mongo.query(query)

end

