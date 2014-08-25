module RemoteResource
  module UrlNaming
    extend ActiveSupport::Concern

    included do
      class_attribute :site, :version, :path_prefix, :path_postfix, :collection, :collection_name, instance_accessor: false

      self.collection = false
    end

    module ClassMethods

      def app_host(app, env = 'development')
        CONFIG[env.to_sym][:apps][app.to_sym]
      end

      def base_url
        determined_url_naming.base_url
      end

      def use_relative_model_naming?
        true
      end

      private

      def determined_url_naming
        RemoteResource::UrlNamingDetermination.new self
      end

    end

  end
end