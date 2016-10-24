module RemoteResource
  class Collection
    include Enumerable

    attr_reader :resource_klass, :resources_collection
    attr_accessor :last_request, :last_response, :meta

    delegate :[], :at, :reverse, :size, to: :to_a

    def initialize(resource_klass, resources_collection, options = {})
      @resource_klass       = resource_klass
      @resources_collection = resources_collection
      @options              = options
    end

    def each(&block)
      if resources_collection.is_a?(Array)
        if defined?(@collection)
          @collection.each(&block)
        else
          @collection = []
          resources_collection.each do |element|
            record = resource_klass.new(element.merge(@options))
            @collection.push(record)
            yield(record)
          end
        end
      end
    end

    def empty?
      resources_collection.blank?
    end

    def success?
      last_response.success?
    end

    def last_request
      @last_request ||= @options[:last_request]
    end

    def last_response
      @last_response ||= @options[:last_response]
    end

    def meta
      @meta ||= @options[:meta]
    end

    def _response
      warn '[DEPRECATION] `._response` is deprecated. Please use `.last_response` instead.'
    end

  end
end
