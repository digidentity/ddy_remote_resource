module RemoteResource
  module Querying
    module FinderMethods
      extend ActiveSupport::Concern

      module ClassMethods

        def find(id, connection_options = {})
          connection_options.reverse_merge! self.connection_options.to_hash

          response = connection.get determined_request_url(connection_options, id), headers: connection_options[:default_headers] || self.connection_options.headers.merge(connection_options[:headers])
          response = RemoteResource::Response.new response, connection_options
          build_resource_from_response response
        end

        def find_by(params, connection_options = {})
          root_element = connection_options[:root_element] || self.connection_options.root_element

          response = get(pack_up_request_body(params, root_element), connection_options)
          build_resource_from_response response
        end
      end

    end
  end
end