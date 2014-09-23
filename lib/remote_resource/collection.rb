module RemoteResource
  class Collection
    include Enumerable

    delegate :[], :at, :reverse, :size, to: :to_a

    attr_reader :resource_klass, :resources_collection, :_response

    def initialize(resource_klass, resources_collection, response_hash)
      @resource_klass       = resource_klass
      @resources_collection = resources_collection
      @response_hash        = response_hash
      @_response            = response_hash[:_response]
    end

    def each
      if resources_collection.is_a? Array
        resources_collection.each { |element| yield resource_klass.new element.merge(@response_hash) }
      end
    end

    def empty?
      resources_collection.blank?
    end

    def success?
      _response.success?
    end

  end
end
