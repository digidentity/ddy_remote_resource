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
        "#{self.site}#{self.version.presence}#{self.path_prefix.presence}/#{self.url_safe_relative_name}#{self.path_postfix.presence}"
      end

      def url_safe_relative_name
        if self.collection
          relative_name.underscore.downcase.pluralize
        else
          relative_name.underscore.downcase
        end
      end

      def relative_name
        self.collection_name.to_s.presence || self.name.to_s.demodulize
      end

      def use_relative_model_naming?
        true
      end

    end

  end
end