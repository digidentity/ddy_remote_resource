module RemoteResource
  module Builder
    extend ActiveSupport::Concern

    module ClassMethods

      def build_resource_from_response(response)
        build_resource response.sanitized_response_body, response_hash(response)
      end

      def build_resource(collection, response_hash = {})
        if collection.is_a? Hash
          new collection.merge response_hash
        end
      end

      def build_collection_from_response(response)
        build_collection response.sanitized_response_body, response_hash(response)
      end

      def build_collection(collection, response_hash = {})
        if collection.is_a? Array
          RemoteResource::Collection.new self, collection, response_hash
        end
      end

      private

      def response_hash(response_object)
        { _response: response_object }
      end
    end

    def rebuild_resource_from_response(response)
      rebuild_resource response.sanitized_response_body, response_hash(response)
    end

    def rebuild_resource(collection, response_hash = {})
      case collection
      when Hash
        rebuild collection.merge response_hash
      else
        rebuild response_hash
      end and self
    end

    private

    def rebuild(attributes)
      attributes.each do |attribute, value|
        self.public_send "#{attribute}=", value
      end if attributes
    end

    def response_hash(response_object)
      self.class.send :response_hash, response_object
    end

  end
end
