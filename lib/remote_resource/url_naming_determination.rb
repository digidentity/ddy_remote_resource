module RemoteResource
  class UrlNamingDetermination

    attr_reader :resource_klass, :connection_options

    def initialize(resource_klass, connection_options = {})
      @resource_klass     = resource_klass
      @connection_options = connection_options
    end

    def base_url(id = nil, check_collection_options: false)
      site         = connection_options.fetch(:site, resource_klass.site)
      version      = connection_options.fetch(:version, resource_klass.version)
      path_prefix  = connection_options.fetch(:path_prefix, resource_klass.path_prefix)
      path_postfix = connection_options.fetch(:path_postfix, resource_klass.path_postfix)

      File.join(site.to_s, version.to_s, path_prefix.to_s, collection_prefix(check_collection_options).to_s, url_safe_relative_name, id.to_s, path_postfix.to_s).chomp('/')
    end

    def collection_prefix(check_collection_options)
      prefix = connection_options.fetch(:collection_prefix, resource_klass.collection_prefix)

      if prefix.present?
        prefix = "/#{prefix}" unless prefix.chr == '/'
        collection_options = connection_options.fetch(:collection_options, {}).with_indifferent_access

        prefix.gsub(/:\w+/) do |key|
          value = collection_options.fetch(key[1..-1], nil)
          if value.nil?
            raise(RemoteResource::CollectionOptionKeyError, "`collection_prefix` variable `#{key}` is missing from `collection_options`") if check_collection_options
            value = key
          end
          URI.parser.escape(value.to_s)
        end
      end
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
