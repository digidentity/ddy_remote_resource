module RemoteResource
  module Querying
    module PersistenceMethods
      extend ActiveSupport::Concern

      module ClassMethods

        def create(attributes = {}, connection_options = {})
          resource = new attributes
          response = RemoteResource::Request.new(self, :post, attributes, connection_options).perform
          resource.handle_response response
        end
      end

      def update_attributes(attributes = {}, connection_options = {})
        rebuild_resource attributes
        attributes.reverse_merge! id: id
        create_or_update attributes, connection_options
        success? ? self : false
      end

      def save(connection_options = {})
        create_or_update self.attributes, connection_options
        success? ? self : false
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