module RemoteResource
  module Builder

    def build_resource_from_response(response)
      build_resource response.sanitized_response_body, response_hash(response)
    end

    def build_resource(collection, response_hash = {})
      case collection
      when Hash
        new collection.merge response_hash
      when Array
        collection.map { |element| new element.merge response_hash }
      else
        new response_hash
      end
    end

    private

    def response_hash(response_object)
      { _response: response_object }
    end

  end
end