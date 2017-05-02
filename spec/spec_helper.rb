require 'dotenv'
Dotenv.load

require 'simplecov'
SimpleCov.start

require 'bundler/setup'
require 'salesforce_bulk_client'
require 'vcr'
require 'restforce'
require 'multi_json'
require 'addressable/uri'

$client = nil
$test_record_ids = []

ENV_KEYS = %w( SALESFORCE_OAUTH_CONSUMER_KEY
    SALESFORCE_OAUTH_CONSUMER_SECRET
    SALESFORCE_USERNAME
    SALESFORCE_PASSWORD
    SALESFORCE_SECURITY_TOKEN
    SALESFORCE_HOST )

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

VCR.configure do |c|
  c.cassette_library_dir = 'fixtures/vcr_cassettes'
  c.hook_into :webmock
  ENV_KEYS.reject{ |env_key| env_key == 'SALESFORCE_HOST' }.each do |env_key|
    c.filter_sensitive_data("{#{env_key}}") { ENV[env_key] } if !ENV[env_key].nil?
    c.filter_sensitive_data(Addressable::URI.encode_component("{#{env_key}}", Addressable::URI::CharacterClasses::UNRESERVED)) { Addressable::URI.encode_component(ENV[env_key], Addressable::URI::CharacterClasses::UNRESERVED) } if !ENV[env_key].nil?
  end
  c.filter_sensitive_data('{ACCESS_TOKEN}') { |interaction| data = MultiJson.load(interaction.response.body); data['access_token'] if data.is_a?(Hash) }
  c.filter_sensitive_data('{ID_URL}') { |interaction| data = MultiJson.load(interaction.response.body); data['id'] if data.is_a?(Hash) and data.key?('access_token') }
  c.filter_sensitive_data('{SIGNATURE}') { |interaction| data = MultiJson.load(interaction.response.body); data['signature'] if data.is_a?(Hash) and data.key?('access_token') }
  c.filter_sensitive_data('instance.salesforce.com') { |interaction| data = MultiJson.load(interaction.response.body); Addressable::URI.parse(data['instance_url'] ).host if data.is_a?(Hash) and data.key?('access_token') }
  c.filter_sensitive_data('{SESSION_ID}') { |interaction| interaction.request.headers['X-Sfdc-Session']&.first }
  c.filter_sensitive_data('{AUTHORIZATION}') { |interaction| interaction.request.headers['Authorization']&.first }
  c.filter_sensitive_data('instance.salesforce.com') { |interaction| Addressable::URI.parse(interaction.request.uri).host if Addressable::URI.parse(interaction.request.uri).path != '/services/oauth2/token' }
end

def verify_env_is_set
  ENV_KEYS.each do |env|
    raise "ENV['#{env}'] is unknown" if ENV[env].nil?
  end
end