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
          if RemoteResource.find_by_raises_if_resource_not_found
            RemoteResource.deprecator.warn <<-DEPRECATION.strip_heredoc
              [RemoteResource] `find_by` will not raise if the resource is not found in the next major version.
              Use `find_by!` instead if you want to keep this behaviour.
              If everything has been migrated set `RemoteResource.find_by_raises_if_resource_not_found = false` to no longer raise.
            DEPRECATION
            find_by!(params, connection_options)
          else
            begin
              find_by!(params, connection_options)
            rescue RemoteResource::HTTPNotFound
            end
          end
        end

        def find_by!(params, connection_options = {})
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
