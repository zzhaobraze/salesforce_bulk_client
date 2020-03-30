require 'salesforce_bulk_client/connection'
require 'salesforce_bulk_client/job'

module SalesforceBulkClient
  class Client

    DEFAULT_CLIENT_OPTIONS = { salesforce_api_version: '41.0' }

    def initialize(restforce_client, options = {})
      options = {}.merge(DEFAULT_CLIENT_OPTIONS).merge(options)
      @connection = SalesforceBulkClient::Connection.new(options[:salesforce_api_version], restforce_client)
    end

    def delete(sobject, records, get_response = false, batch_size = 10000, timeout = 3600, poll_delay = 5)
      do_operation('delete', sobject, records, nil, get_response, timeout, batch_size, poll_delay)
    end

    def insert(sobject, records, get_response = false, batch_size = 10000, timeout = 3600, poll_delay = 5)
      do_operation('insert', sobject, records, nil, get_response, timeout, batch_size, poll_delay)
    end

    def query(sobject, query, get_response = false, batch_size = 10000, timeout = 3600, poll_delay = 5)
      do_operation('query', sobject, query,nil, get_response, timeout, batch_size, poll_delay)
    end

    def update(sobject, records, get_response = false, batch_size = 10000, timeout = 3600, poll_delay = 5)
      do_operation('update', sobject, records, nil, get_response, timeout, batch_size, poll_delay)
    end

    def upsert(sobject, records, external_field, get_response = false, batch_size = 10000, timeout = 3600, poll_delay = 5)
      do_operation('upsert', sobject, records, external_field, get_response, timeout, batch_size, poll_delay)
    end

    def job_from_id(job_id)
      job = SalesforceBulkClient::Job.new(job_id: job_id, connection: @connection)
      job_status = job.check_job_status
      batches = job.list_batches
      job.instance_variable_set(:@operation, job_status.operation)
      job.instance_variable_set(:@sobject, job_status.object)
      job.instance_variable_set(:@batch_ids, batches.map { |batch_info| batch_info.id })
      job
    end

    private

    def do_operation(operation, sobject, records, external_field, get_response, timeout, batch_size, poll_delay)
      job = SalesforceBulkClient::Job.new(
          operation: operation,
          sobject: sobject,
          records: records,
          external_field: external_field,
          connection: @connection
      )

      job.create_job(batch_size)
      operation.to_s == 'query' ? job.add_query : job.add_batches
      job.close_job
      job.get_job_result(get_response, timeout, poll_delay)
    end

  end
end