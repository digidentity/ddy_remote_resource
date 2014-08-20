module RemoteResource
  module Querying
    module PersistenceMethods
      extend ActiveSupport::Concern

      def save(connection_options = {})
        create_or_update params, connection_options
      end

      def create_or_update(attributes = {}, connection_options = {})
        root_element = connection_options[:root_element] || self.connection_options.root_element

        if attributes.has_key? :id
          patch(pack_up_request_body(attributes, root_element), connection_options)
        else
          post(pack_up_request_body(attributes, root_element), connection_options)
        end
      end

    end
  end
end