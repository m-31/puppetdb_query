source 'https://rubygems.org'

gemspec

# only for local testing but not needed for spec tests
group :test do
  gem 'ruby-puppetdb', '=1.5.3', :require => false if RUBY_VERSION =~ /^1\./
  gem 'puppet',        '=3.8.7', :require => false if RUBY_VERSION =~ /^1\./
end