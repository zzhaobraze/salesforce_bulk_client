require 'fire_poll'
require 'multi_json'

module SalesforceBulkClient

  class Job

    BATCH_CHARACTER_LIMIT = 10000000

    attr_reader :job_id

    def initialize(args)
      @job_id = args[:job_id]
      @operation = args[:operation]
      @sobject = args[:sobject]
      @external_field = args[:external_field]
      @records = args[:records]
      @connection = args[:connection]
      @batch_ids = []
    end

    def create_job(batch_size, concurrency_mode = 'Parallel')
      @batch_size = batch_size
      create_job_request = { operation: @operation.to_s.downcase, object: @sobject, contentType: 'JSON', concurrencyMode: concurrency_mode }
      if !@external_field.nil?
        create_job_request[:externalIdFieldName] = @external_field
      end
      create_job_result = @connection.post_request('job', create_job_request)
      @job_id = create_job_result.id
    end

    def close_job
      close_job_request = { state: 'Closed' }
      @connection.post_request("job/#{@job_id}", close_job_request)
    end

    def add_query
      add_query_result = @connection.post_request("job/#{@job_id}/batch", @records, false)
      @batch_ids << add_query_result.id
    end

    def add_batches
      raise 'Records must be an array of hashes.' unless @records.is_a? Array
      @records.each_slice(@batch_size) do |batch|
        @batch_ids.concat(add_batch(batch))
      end
    end

    def add_batch(batch)
      batch_ids = []
      batch_groups = []
      batch_size = MultiJson.dump(batch).size
      if batch_size <= BATCH_CHARACTER_LIMIT
        batch_groups << batch
      else

        # Split batch into sub-batches
        batch_group = []
        batch_group_size = MultiJson.dump(batch_group).size
        batch.each do |record|
          record_size = MultiJson.dump(record).size
          if batch_group_size + record_size + 1 > BATCH_CHARACTER_LIMIT
            batch_groups << batch_group.dup
            batch_group.clear
            batch_group_size = MultiJson.dump(batch_group).size
          end
          batch_group << record.dup
          batch_group_size += record_size + 1
        end

        # Add remaining records
        if !batch_group.empty?
          batch_groups << batch_group.dup
          batch_group.clear
        end

      end

      batch_groups.each do |batch_group|
        add_batch_result = @connection.post_request("job/#{@job_id}/batch", batch_group)
        batch_ids << add_batch_result.id
      end

      batch_ids
    end

    def check_job_status
      @connection.get_request("job/#{@job_id}")
    end

    def check_batch_status(batch_id)
      @connection.get_request("job/#{@job_id}/batch/#{batch_id}")
    end

    def list_batches
      @connection.get_request("job/#{@job_id}/batch")&.batchInfo
    end

    def get_job_result(return_result, timeout, poll_delay)
      batch_infos = []
      polling_started = false
      polling_completed = false
      FirePoll.poll("Timeout waiting for Salesforce to process job batches #{@batch_ids} of job #{@job_id}.", timeout) do
        sleep poll_delay if polling_started
        polling_started = true
        job_status = self.check_job_status
        if job_status.state == 'Closed'
          batch_info_map = {}

          batches_ready = @batch_ids.all? do |batch_id|
            batch_info = batch_info_map[batch_id] = self.check_batch_status(batch_id)
            batch_info.state != 'Queued' && batch_info.state != 'InProgress'
          end

          if batches_ready
            @batch_ids.each do |batch_id|
              batch_infos.insert(0, batch_info_map[batch_id])
              @batch_ids.delete(batch_id)
            end
          end
          polling_completed = true if @batch_ids.empty?
        else
          polling_completed = true
        end
        polling_completed
      end
      job_status = self.check_job_status

      batch_infos.each_with_index do |batch_info, i|
        if batch_info.state == 'Completed' && return_result == true
          batch_infos[i].merge!({ 'response' => self.get_batch_result(batch_info.id)})
        end
      end

      job_status.merge!({ 'batches' => batch_infos })
      job_status
    end

    def get_batch_result(batch_id)
      batch_results = @connection.get_request("job/#{@job_id}/batch/#{batch_id}/result")
      results = []
      if @operation.to_s != 'query'
        results = batch_results
      else
        batch_results.each do |batch_result_id|
          results.concat(@connection.get_request("job/#{@job_id}/batch/#{batch_id}/result/#{batch_result_id}"))
        end
      end
      results
    end

    def each_batch(timeout = 3600, poll_delay = 5)
      job_result = self.get_job_result(false, timeout, poll_delay)
      job_result.batches.each do |batch_info|
        batch_result = nil
        if batch_info.state == 'Completed'
          batch_result = self.get_batch_result(batch_info.id)
        end
        yield(batch_info, batch_result)
      end
    end

  end

end
