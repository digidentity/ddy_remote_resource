module RemoteResource
  module REST
    extend ActiveSupport::Concern

    module ClassMethods

      def get(attributes = {}, connection_options = {})
        connection_options.reverse_merge! self.connection_options.to_hash

        response = connection.get determined_request_url(connection_options), params: attributes, headers: connection_options[:default_headers] || self.connection_options.headers.merge(connection_options[:headers])
        if response.success?
          unpack_response_body(response.body, connection_options[:root_element]).merge! assign_response(response)
        else
          assign_response(response)
        end
      end

      private

      def assign_response(response)
        { _response: RemoteResource::Response.new(response) }
      end

    end

    def post(attributes = {}, connection_options = {})
      connection_options.reverse_merge! self.connection_options.to_hash

      response = self.class.connection.post determined_request_url(connection_options), body: attributes, headers: connection_options[:default_headers] || self.connection_options.headers.merge(connection_options[:headers])
      assign_response response

      if response.success?
        true
      elsif response.response_code == 422
        assign_errors JSON.parse(response.body), connection_options[:root_element]
        false
      else
        false
      end
    end

    def patch(attributes = {}, connection_options = {})
      connection_options.reverse_merge! self.connection_options.to_hash

      response = self.class.connection.patch determined_request_url(connection_options), body: attributes, headers: connection_options[:default_headers] || self.connection_options.headers.merge(connection_options[:headers])
      assign_response response

      if response.success?
        true
      elsif response.response_code == 422
        assign_errors JSON.parse(response.body), connection_options[:root_element]
        false
      else
        false
      end
    end

    private

    def assign_response(response)
      @_response = RemoteResource::Response.new response
    end

  end
end