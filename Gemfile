source 'https://rubygems.org'

gemspec

# only for local testing but not needed for spec tests
group :test do
  gem 'ruby-puppetdb', '=1.5.3'
  gem 'puppet',        '=3.8.8', :require => false if RUBY_VERSION =~ /^1\./
end