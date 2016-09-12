module RemoteResource
  module Querying
    module PersistenceMethods
      extend ActiveSupport::Concern

      module ClassMethods

        def create(attributes = {}, connection_options = {})
          resource = new(attributes)
          response = RemoteResource::Request.new(self, :post, attributes, connection_options).perform
          resource.handle_response(response)
        end

        def destroy(id, connection_options = {})
          resource = new
          response = RemoteResource::Request.new(self, :delete, { id: id }, connection_options.reverse_merge(no_attributes: true)).perform
          resource.handle_response(response)
        end
      end

      def update_attributes(attributes = {}, connection_options = {})
        rebuild_resource(attributes)
        create_or_update(attributes.reverse_merge(id: id), connection_options)
        success? ? self : false
      end

      def save(connection_options = {})
        create_or_update(self.attributes, connection_options)
        success? ? self : false
      end

      def create_or_update(attributes = {}, connection_options = {})
        if attributes.has_key?(:id) && attributes[:id].present?
          response = RemoteResource::Request.new(self, :patch, attributes.except(:id), connection_options.merge(id: attributes[:id])).perform
        else
          response = RemoteResource::Request.new(self, :post, attributes.except(:id), connection_options).perform
        end
        handle_response(response)
      end

      def destroy(connection_options = {})
        id.present? || raise(RemoteResource::IdMissingError.new("`id` is missing from resource"))
        response = RemoteResource::Request.new(self, :delete, { id: id }, connection_options.reverse_merge(no_attributes: true)).perform
        handle_response(response)
        success? ? self : false
      end

    end
  end
end
