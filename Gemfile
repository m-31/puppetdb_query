source 'https://rubygems.org'

gemspec

# only for local testing but not needed for spec tests
group :test do
  gem 'mongo',         '>=2.2.0' # if you want to work with a mongodb
  gem 'puppet',        '=3.8.7'  if RUBY_VERSION !~ /^1\./
  gem 'rake',          '~>11'
  gem 'rubocop'                  if RUBY_VERSION !~ /^1\./
  # rubocop:disable Bundler/DuplicatedGem
  gem 'rubocop',       '=0.39.0' if RUBY_VERSION =~ /^1\./
  # rubocop:enable Bundler/DuplicatedGem
  gem 'ruby-puppetdb', '=2.2.0'  if RUBY_VERSION !~ /^1\./
end
