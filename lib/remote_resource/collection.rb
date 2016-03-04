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

    def each(&block)
      if resources_collection.is_a? Array
        if defined?(@collection)
          @collection.each(&block)
        else
          @collection = []
          resources_collection.each do |element|
            record = resource_klass.new element.merge(@response_hash)
            @collection << record
            yield(record)
          end
        end
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
