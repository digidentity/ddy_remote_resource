module RemoteResource
  class UrlNamingDetermination

    attr_reader :resource_klass, :connection_options

    def initialize(resource_klass, connection_options = {})
      @resource_klass     = resource_klass
      @connection_options = connection_options
    end

    def base_url
      site         = connection_options.fetch(:site, resource_klass.site)
      version      = connection_options.fetch(:version, resource_klass.version)
      path_prefix  = connection_options.fetch(:path_prefix, resource_klass.path_prefix)
      path_postfix = connection_options.fetch(:path_postfix, resource_klass.path_postfix)

      "#{site}#{version.presence}#{path_prefix.presence}/#{url_safe_relative_name}#{path_postfix.presence}"
    end

    def url_safe_relative_name
      collection = connection_options.fetch(:collection, resource_klass.collection)

      if collection
        relative_name.underscore.downcase.pluralize
      else
        relative_name.underscore.downcase
      end
    end

    def relative_name
      collection_name = connection_options.fetch(:collection_name, resource_klass.collection_name)

      collection_name.to_s.presence || resource_klass.name.to_s.demodulize
    end

  end
end