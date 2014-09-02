module RemoteResource
  module Querying
    module PersistenceMethods
      extend ActiveSupport::Concern

      module ClassMethods

        def create(attributes = {}, connection_options = {})
          response = RemoteResource::Request.new(self, :post, attributes, connection_options).perform
          handle_response response
        end
      end

      def save(connection_options = {})
        create_or_update params, connection_options
        success?
      end

      def create_or_update(attributes = {}, connection_options = {})
        if attributes.has_key? :id
          response = RemoteResource::Request.new(self, :patch, attributes, connection_options).perform
        else
          response = RemoteResource::Request.new(self, :post, attributes, connection_options).perform
        end
        handle_response response
      end

    end
  end
end