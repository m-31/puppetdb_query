# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'puppetdb_query/version'

Gem::Specification.new do |spec|
  spec.name          = 'puppetdb_query'
  spec.version       = PuppetDBQuery::VERSION
  spec.authors       = ["Michael Meyling"]
  spec.email         = ["search@meyling.com"]
  spec.summary       = 'access puppetdb data from other sources'
  spec.description   = 'Allow puppetdb access from resources like mongodb.'
  spec.homepage      = 'https://github.com/m-31/puppetdb_query'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.required_ruby_version = '>= 1.9.3'
  spec.require_paths = ['lib']
  spec.post_install_message = "  Sitting quietly, doing nothing, spring comes," \
                              " and grass grows by itself."

  spec.add_development_dependency "rspec"
  spec.add_development_dependency "easy_diff"
end
