module RemoteResource
  module Connection
    extend ActiveSupport::Concern

    included do
      class_attribute :extension, :default_headers, instance_accessor: false

      self.default_headers = {}
    end

    module ClassMethods

      def connection
        Typhoeus::Request
      end

      def content_type=(content_type)
        warn '[DEPRECATION] `.content_type=` is deprecated. Please use `.extension=` instead.'
        self.extension = content_type
      end

      def content_type
        warn '[DEPRECATION] `.content_type` is deprecated. Please use `.extension` instead.'
        self.extension
      end

      def extra_headers=(_)
        warn '[DEPRECATION] `.extra_headers=` is deprecated. Please overwrite the .headers method to set custom headers.'
      end

      def extra_headers
        warn '[DEPRECATION] `.extra_headers` is deprecated. Please overwrite the .headers method to set custom headers.'
      end

      def headers=(_)
        warn '[WARNING] `.headers=` can not be used to set custom headers. Please overwrite the .headers method to set custom headers.'
      end

      def headers
        {}
      end

    end
  end
end
