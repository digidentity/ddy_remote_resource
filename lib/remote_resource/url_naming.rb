module RemoteResource
  module UrlNaming
    extend ActiveSupport::Concern

    included do
      class_attribute :site, :version, :path_prefix, :path_postfix, :collection_prefix, :collection, :collection_name, instance_accessor: false

      self.collection = false
    end

    module ClassMethods

      def app_host(*_)
        warn '[DEPRECATION] `.app_host` is deprecated. Please use a different method to determine the site.'
      end

      def base_url(connection_options = {})
        RemoteResource::UrlNamingDetermination.new(self, self.connection_options.to_hash.merge(connection_options)).base_url(connection_options[:id], check_collection_options: false)
      end

      def use_relative_model_naming?
        true
      end

    end

  end
end
