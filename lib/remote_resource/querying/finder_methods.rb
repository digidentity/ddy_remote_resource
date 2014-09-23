module RemoteResource
  module Querying
    module FinderMethods
      extend ActiveSupport::Concern

      module ClassMethods

        def find(id, connection_options = {})
          connection_options.merge! no_params: true
          response = RemoteResource::Request.new(self, :get, { id: id }, connection_options).perform
          build_resource_from_response response
        end

        def find_by(params, connection_options = {})
          response = RemoteResource::Request.new(self, :get, params, connection_options).perform
          build_resource_from_response response
        end

        def all(connection_options = {})
          connection_options.merge! collection: true
          response = RemoteResource::Request.new(self, :get, {}, connection_options).perform
          build_collection_from_response response
        end

        def where(params, connection_options = {})
          connection_options.merge! collection: true
          response = RemoteResource::Request.new(self, :get, params, connection_options).perform
          build_collection_from_response response
        end
      end

    end
  end
end
