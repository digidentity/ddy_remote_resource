module RemoteResource
  module REST
    extend ActiveSupport::Concern

    module ClassMethods

      def get(attributes = {}, connection_options = {})
        connection_options.reverse_merge! self.connection_options.to_hash
        response = connection.get determined_request_url(connection_options), params: attributes, headers: determined_headers(connection_options)
        RemoteResource::Response.new response, connection_options
      end

      def post(attributes = {}, connection_options = {})
        connection_options.reverse_merge! self.connection_options.to_hash
        response = connection.post determined_request_url(connection_options), body: attributes, headers: determined_headers(connection_options)
        RemoteResource::Response.new response, connection_options
      end

    end

    def post(attributes = {}, connection_options = {})
      connection_options.reverse_merge! self.connection_options.to_hash
      response = self.class.connection.post determined_request_url(connection_options), body: attributes, headers: determined_headers(connection_options)
      response = RemoteResource::Response.new response, connection_options
      assign_response response
      return_response response, connection_options
    end

    def patch(attributes = {}, connection_options = {})
      connection_options.reverse_merge! self.connection_options.to_hash
      response = self.class.connection.patch determined_request_url(connection_options), body: attributes, headers: determined_headers(connection_options)
      response = RemoteResource::Response.new response, connection_options
      assign_response response
      return_response response, connection_options
    end

    private

    def assign_response(response)
      @_response = response
    end

    def return_response(response, connection_options = {})
      if response.success?
        true
      elsif response.response_code == 422
        assign_errors JSON.parse(response.response_body), connection_options[:root_element]
        false
      else
        false
      end
    end

  end
end