module RemoteResource
  module Querying
    module FinderMethods
      extend ActiveSupport::Concern

      module ClassMethods

        def find(id, connection_options = {})
          response = RemoteResource::Request.new(self, :get, {}, connection_options.merge(id: id)).perform
          build_resource_from_response(response)
        end

        def find_by(params, connection_options = {})
          response = RemoteResource::Request.new(self, :get, {}, connection_options.deep_merge(id: params[:id], params: params.except(:id))).perform
          build_resource_from_response(response)
        end

        def all(connection_options = {})
          response = RemoteResource::Request.new(self, :get, {}, connection_options.merge(collection: true)).perform
          build_collection_from_response(response)
        end

        def where(params, connection_options = {})
          response = RemoteResource::Request.new(self, :get, {}, connection_options.deep_merge(collection: true, params: params)).perform
          build_collection_from_response(response)
        end
      end

    end
  end
end
