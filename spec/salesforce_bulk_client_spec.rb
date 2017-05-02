require 'spec_helper'
require 'set'

RSpec.describe SalesforceBulkClient do
  it 'has a version number' do
    expect(SalesforceBulkClient::VERSION).not_to be nil
  end

  it 'logs into Salesforce successfully' do
    VCR.use_cassette('salesforce/login') do |cassette|
      verify_env_is_set if cassette.originally_recorded_at.nil?
      expect { $client = SalesforceBulkClient::Client.new(Restforce.new(
          username:       ENV['SALESFORCE_USERNAME'],
          password:       ENV['SALESFORCE_PASSWORD'],
          security_token: ENV['SALESFORCE_SECURITY_TOKEN'],
          client_id:      ENV['SALESFORCE_OAUTH_CONSUMER_KEY'],
          client_secret:  ENV['SALESFORCE_OAUTH_CONSUMER_SECRET'].to_i,
          host:           ENV['SALESFORCE_HOST'],
          timeout:        60) ) }.to_not raise_error
    end
  end

  it 'inserts records in bulk' do
    VCR.use_cassette('salesforce/insert') do |cassette|
      verify_env_is_set if cassette.originally_recorded_at.nil?
      records = [ { Name: 'Test Account' } ]
      insert_results = $client.insert('Account', records, true)
      $test_record_ids = insert_results.batches.map { |batch| batch.response.map { |record| record.id } }&.flatten&.compact
      expect(insert_results.numberRecordsFailed).to eq(0)
      expect(insert_results.numberRecordsProcessed).to eq(records.size)
    end
  end

  it 'updates records in bulk' do
    VCR.use_cassette('salesforce/update') do |cassette|
      verify_env_is_set if cassette.originally_recorded_at.nil?
      records = $test_record_ids.map { |record_id| { Id: record_id, Name: 'Test Updated Account' } }
      update_results = $client.update('Account', records, true)
      expect(update_results.numberRecordsFailed).to eq(0)
      expect(update_results.numberRecordsProcessed).to eq(records.size)
    end
  end

  it 'upserts records in bulk' do
    VCR.use_cassette('salesforce/upsert') do |cassette|
      verify_env_is_set if cassette.originally_recorded_at.nil?
      records = $test_record_ids.map { |record_id| { Id: record_id, Name: 'Test Upserted Account' } } + [ { Name: 'Test Upserted Account' }]
      upsert_results = $client.upsert('Account', records, 'Id', true)
      $test_record_ids = upsert_results.batches.map { |batch| batch.response.map { |record| record.id } }&.flatten&.compact
      expect(upsert_results.numberRecordsFailed).to eq(0)
      expect(upsert_results.numberRecordsProcessed).to eq(records.size)
    end
  end

  it 'executes a bulk query' do
    VCR.use_cassette('salesforce/query') do |cassette|
      verify_env_is_set if cassette.originally_recorded_at.nil?
      query_results = $client.query('Account', "select Id, Name from Account where Id in (#{$test_record_ids.map { |id| "'#{id}'" }.join(', ') })", true)
      retrieved_ids = query_results.batches.map { |batch| batch.response.map { |record| record.Id } }&.flatten&.compact
      expect(retrieved_ids.to_set).to eq($test_record_ids.to_set)
    end
  end

  it 'allows processing of batches without preloading all batches' do
    VCR.use_cassette('salesforce/batch_processing') do |cassette|
      verify_env_is_set if cassette.originally_recorded_at.nil?
      query_results = $client.query('Account', "select Id, Name from Account where Id in (#{$test_record_ids.map { |id| "'#{id}'" }.join(', ') })", false)
      retrieved_ids = Set.new
      $client.job_from_id(query_results.id).each_batch do |batch, batch_results|
        retrieved_ids += batch_results.map { |record| record.Id }
      end
      expect(retrieved_ids.to_set).to eq($test_record_ids.to_set)
    end
  end

  it 'deletes records in bulk' do
    VCR.use_cassette('salesforce/delete') do |cassette|
      verify_env_is_set if cassette.originally_recorded_at.nil?
      records = $test_record_ids.map { |record_id| { Id: record_id } }
      delete_results = $client.delete('Account', records, true)
      expect(delete_results.numberRecordsFailed).to eq(0)
      expect(delete_results.numberRecordsProcessed).to eq(records.size)
    end
  end

end
