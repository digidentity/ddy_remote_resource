module RemoteResource
  module Builder
    extend ActiveSupport::Concern

    module ClassMethods

      def build_resource_from_response(response)
        build_resource(response.attributes, { last_request: response.request, last_response: response, meta: response.meta })
      end

      def build_resource(collection, options = {})
        if collection.is_a?(Hash)
          new(collection.merge(options))
        end
      end

      def build_collection_from_response(response)
        build_collection(response.attributes, { last_request: response.request, last_response: response, meta: response.meta })
      end

      def build_collection(collection, options = {})
        if collection.is_a?(Array)
          RemoteResource::Collection.new(self, collection, options)
        else
          []
        end
      end
    end

    def rebuild_resource_from_response(response)
      rebuild_resource(response.attributes, { last_request: response.request, last_response: response, meta: response.meta })
    end

    def rebuild_resource(collection, options = {})
      if collection.is_a?(Hash)
        self.attributes = collection.merge(options)
      else
        self.attributes = options
      end and self
    end

  end
end
