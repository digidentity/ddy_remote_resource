module RemoteResource
  module Connection
    extend ActiveSupport::Concern

    module ClassMethods

      attr_accessor :content_type
      attr_writer :headers

      def connection
        Typhoeus::Request
      end

      def headers
        @headers ||= {}
        @headers.merge("Accept" => "application/json")
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

      def determined_headers(connection_options = {})
        connection_options[:default_headers] || self.connection_options.headers.merge(connection_options[:headers] || {})
      end

    end

    private

    def determined_request_url(connection_options = {})
      if connection_options[:collection] && self.id.present?
        self.class.send :determined_request_url, connection_options, self.id
      else
        self.class.send :determined_request_url, connection_options
      end
    end

    def determined_headers(connection_options = {})
      self.class.send :determined_headers, connection_options
    end

  end
end