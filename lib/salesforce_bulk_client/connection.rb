require 'multi_json'

module SalesforceBulkClient
  class Connection

    def initialize(api_version, restforce_client)
      @restforce_client = restforce_client
      @api_version = api_version
      @path_prefix = "/services/async/#{@api_version}/"
      @restforce_client.authenticate!
    end

    def post_request(path, post_data, as_json = true)
      authenticate_results = @restforce_client.authenticate!
      response = @restforce_client.post do |request|
        request.url [ @path_prefix, path ].join('/')
        request.headers['Content-Type'] = 'application/json'
        request.headers['X-SFDC-Session'] = authenticate_results.access_token
        request.body = as_json ? MultiJson.dump(post_data) : post_data
      end
      response.body
    end

    def get_request(path)
      authenticate_results = @restforce_client.authenticate!
      response = @restforce_client.get do |request|
        request.url "#{@path_prefix}#{path}"
        request.headers['Content-Type'] = 'application/json'
        request.headers['X-SFDC-Session'] = authenticate_results.access_token
      end
      response.body
    end

  end
end
