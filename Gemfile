source 'https://rubygems.org'

gemspec

# only for local testing but not needed for spec tests
group :test do
  gem 'ruby-puppetdb', '=1.5.3'  if RUBY_VERSION !~ /^1\./
  gem 'puppet',        '=3.8.7'  if RUBY_VERSION !~ /^1\./
  gem "rubocop",       '=0.39.0' if RUBY_VERSION =~ /^1\./
end