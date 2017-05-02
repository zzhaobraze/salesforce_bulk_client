# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'salesforce_bulk_client/version'

Gem::Specification.new do |spec|
  spec.name          = 'salesforce_bulk_client'
  spec.version       = SalesforceBulkClient::VERSION
  spec.authors       = ['David Massad']
  spec.email         = ['david.massad@fronteraconsulting.net']
  spec.license       = 'MIT'

  spec.summary       = 'Salesforce JSON-based Bulk API Client'
  spec.homepage      = 'https://github.com/FronteraConsulting/salesforce_bulk_client'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'restforce', '~> 2.5', '>= 2.5.3'
  spec.add_dependency 'multi_json', '~> 1.12', '>= 1.12.1'
  spec.add_dependency 'fire_poll', '~> 1.2', '>= 1.2.0'

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.5'
  spec.add_development_dependency 'simplecov', '~> 0.14.1'
  spec.add_development_dependency 'dotenv', '~> 2.2', '>= 2.2.1'
  spec.add_development_dependency 'vcr', '~> 3.0', '>= 3.0.3'
  spec.add_development_dependency 'webmock', '~> 3.0', '>= 3.0.1'
  spec.add_development_dependency 'addressable', '~> 2.5', '>= 2.5.1'
end
