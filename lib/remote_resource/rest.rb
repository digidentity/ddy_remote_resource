module RemoteResource
  module REST
    extend ActiveSupport::Concern

    module ClassMethods

      def get(attributes = {}, connection_options = {})
        connection_options.reverse_merge! self.connection_options.to_hash
        response = connection.get determined_request_url(connection_options), params: attributes, headers: connection_options[:default_headers] || self.connection_options.headers.merge(connection_options[:headers])
        RemoteResource::Response.new response, connection_options
      end

      def post(attributes = {}, connection_options = {})
        connection_options.reverse_merge! self.connection_options.to_hash
        response = connection.post determined_request_url(connection_options), body: attributes, headers: connection_options[:default_headers] || self.connection_options.headers.merge(connection_options[:headers])
        RemoteResource::Response.new response, connection_options
      end

      private

      def determined_request_url(connection_options = {}, id = nil)
        base_url     = connection_options[:base_url].presence     || self.connection_options.base_url
        content_type = connection_options[:content_type].presence || self.connection_options.content_type

        if id.present?
          "#{base_url}/#{id}#{content_type}"
        else
          "#{base_url}#{content_type}"
        end
      end

    end

    def post(attributes = {}, connection_options = {})
      connection_options.reverse_merge! self.connection_options.to_hash
      response = self.class.connection.post determined_request_url(connection_options), body: attributes, headers: connection_options[:default_headers] || self.connection_options.headers.merge(connection_options[:headers])
      response = RemoteResource::Response.new response, connection_options
      assign_response response
      return_response response, connection_options
    end

    def patch(attributes = {}, connection_options = {})
      connection_options.reverse_merge! self.connection_options.to_hash
      response = self.class.connection.patch determined_request_url(connection_options), body: attributes, headers: connection_options[:default_headers] || self.connection_options.headers.merge(connection_options[:headers])
      response = RemoteResource::Response.new response, connection_options
      assign_response response
      return_response response, connection_options
    end

    private

    def determined_request_url(connection_options = {})
      if connection_options[:collection] && self.id.present?
        self.class.send :determined_request_url, connection_options, self.id
      else
        self.class.send :determined_request_url, connection_options
      end
    end

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