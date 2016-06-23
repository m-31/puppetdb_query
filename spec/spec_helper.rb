$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'puppetdb_query'

# we want to be able to test protected or private methods
RSpec.configure do |config|
  config.before(:each) do
    described_class.send(:public, *described_class.protected_instance_methods)
    described_class.send(:public, *described_class.private_instance_methods)
  end
end
