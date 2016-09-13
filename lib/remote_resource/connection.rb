module RemoteResource
  module Connection
    extend ActiveSupport::Concern

    included do
      class_attribute :extension, :default_headers, :extra_headers, instance_accessor: false

      self.default_headers = {}
      self.extra_headers   = {}
    end

    module ClassMethods

      def connection
        Typhoeus::Request
      end

      def content_type=(content_type)
        warn '[DEPRECATION] `.content_type=` is deprecated.  Please use `.extension=` instead.'
        self.extension = content_type
      end

      def content_type
        warn '[DEPRECATION] `.content_type` is deprecated.  Please use `.extension` instead.'
        self.extension
      end

      def headers
        (self.default_headers || {}).merge(self.extra_headers || {})
      end

    end
  end
end
