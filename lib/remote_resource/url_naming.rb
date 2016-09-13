module RemoteResource
  module UrlNaming
    extend ActiveSupport::Concern

    included do
      class_attribute :site, :version, :path_prefix, :path_postfix, :collection_prefix, :collection, :collection_name, instance_accessor: false

      self.collection = false
    end

    module ClassMethods

      def app_host(app, env = 'development')
        warn '[DEPRECATION] `.app_host` is deprecated. Please use a different method to determine the site.'
        CONFIG[env.to_sym][:apps][app.to_sym]
      end

      def base_url
        warn '[DEPRECATION] `.base_url` is deprecated. Please use the connection_options[:base_url] when querying instead.'
      end

      def use_relative_model_naming?
        true
      end

    end

  end
end
