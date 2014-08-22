module RemoteResource
  module Connection
    extend ActiveSupport::Concern

    included do
      class_attribute :content_type, :default_headers, :extra_headers, instance_accessor: false

      self.content_type    = '.json'
      self.default_headers = { "Accept" => "application/json" }
    end

    module ClassMethods

      def connection
        Typhoeus::Request
      end

      def headers
        self.default_headers.merge self.extra_headers || {}
      end

    end
  end
end